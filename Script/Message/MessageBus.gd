class_name MsgBus
extends BaseClass
## 消息总线（设计见 Script/Message/Message.md）：按"接收方 ID"收发，一个 ID 一个 MessageNode。
## 上层的 Msg（MessageHub.gd）只负责"每种消息用什么 ID 规则"，实际的收发都在本类。
## 被谁用：MessageHub 的所有 send_/listen_ 都落到这里。
## 关于 identity：接收器可以登记为"绑定到某个 identity（如 '人类'）"，
## 该 identity 的角色换人（重生/换身）时，接收器会被迁到新角色对应的节点上，
## 调用方手里的旧 ID 由 _aliases 顺着别名链解析成新 ID。

## 全部节点：ID -> 收件箱。
## ID 由 MessageHub 用 format_ID 拼出（如 "char->1->key->32"）。
static var _nodes: Dictionary[String, MessageNode] = {}   

## 迁移别名：旧节点 ID -> 新节点 ID。identity 接收器被迁走后，调用方手里仍握着
## 监听时返回的旧 ID，unlisten 时顺着别名链找到当前节点，避免取消不掉而泄漏。
static var _aliases: Dictionary[String, String] = {}

## 绑定到 identity 的接收器登记：identity -> [[当前节点ID, receiver, 节点ID工厂], ...]
## identity 换角色时按工厂算出新节点，把接收器迁过去（见 rebind_identity）。
static var _identity_bindings: Dictionary[String, Array] = {}

## 确保该 ID 有节点（没有就建一个空收件箱）。
## 被谁用：listen、_move_identity_receiver。
static func _init_message_node(id: String) -> void:
    if _nodes.has(id):
        return
    _nodes[id] = MessageNode.new()

## identity_bound 为 true 时记入 identity_receivers（同样参与广播，identity 变更时会迁移）。
## once 为 true 时记入一次性列表：**广播一次后自动移除**（临时监听用它，不必再手工 unlisten）。
## 返回 ID 本身（调用方要拿它去 unlisten）。
## 被谁用：MessageHub 的各 listen_*。
static func listen(id: String, receiver: Callable, identity_bound: bool = false, once: bool = false) -> String:
    if not _nodes.has(id):
        _init_message_node(id)
    var node: MessageNode = _nodes[id]
    if once:
        if identity_bound:
            node.once_identity_receivers.append(receiver)
        else:
            node.once_receivers.append(receiver)
    elif identity_bound:
        node.identity_receivers.append(receiver)
    else:
        node.receivers.append(receiver)
    return id

## 注销接收器：四个列表里都删（并清掉 identity 登记），空了就删节点。
## 一次性接收器通常不用手工注销（send 调完自己就移除了），但要提前取消也得删得掉。
## 被谁用：MessageHub 的各 unlisten_*（也用于"换绑"时先退订）。
static func unlisten(id: String, receiver: Callable) -> void:
    # 同步清理 identity 登记，避免 identity 之后出现时把已注销的接收器又迁回来
    for identity in _identity_bindings:
        var bucket: Array = _identity_bindings[identity]
        for i in range(bucket.size() - 1, -1, -1):
            if bucket[i][1] == receiver:
                bucket.remove_at(i)
    var real_id: String = _resolve_alias(id)
    if not _nodes.has(real_id):
        return
    var node: MessageNode = _nodes[real_id]
    node.receivers.erase(receiver)
    node.identity_receivers.erase(receiver)
    node.once_receivers.erase(receiver)
    node.once_identity_receivers.erase(receiver)
    if node.receivers.is_empty() and node.identity_receivers.is_empty() \
            and node.once_receivers.is_empty() and node.once_identity_receivers.is_empty():
        _nodes.erase(real_id)


## ---------- identity 接收器 ----------

## 把 receiver 登记为"绑定到 identity"：identity 换角色时由 rebind_identity 迁移。
## node_id 为当前所在节点；factory(char_) 产出该接收器在新角色下应处的节点 ID。
## 被谁用：MessageHub 里"监听对象是 identity 名字而非具体角色"的那些 listen_*。
static func bind_identity_receiver(identity: String, node_id: String, receiver: Callable, factory: Callable) -> void:
    if not _identity_bindings.has(identity):
        _identity_bindings[identity] = []
    _identity_bindings[identity].append([node_id, receiver, factory])

## identity 出现/换角色：把绑定到它的接收器从旧节点迁到该角色对应的新节点。
## 被谁用：MessageHub（角色重生/换身时）。
static func rebind_identity(identity: String, char_: Character) -> void:
    if not _identity_bindings.has(identity):
        return
    for item in _identity_bindings[identity]:
        var old_id: String = item[0]
        var receiver: Callable = item[1]
        var factory: Callable = item[2]
        var new_id: String = factory.call(char_)
        if old_id == new_id:
            continue
        _move_identity_receiver(old_id, new_id, receiver)
        item[0] = new_id

## 把 receiver 从 old_id 的 identity 列表搬到 new_id 的 identity 列表（一次性身份接收器也照样搬）。
## 被谁用：rebind_identity。
static func _move_identity_receiver(old_id: String, new_id: String, receiver: Callable) -> void:
    var was_once: bool = false
    if _nodes.has(old_id):
        var old_node: MessageNode = _nodes[old_id]
        was_once = old_node.once_identity_receivers.has(receiver)
        old_node.identity_receivers.erase(receiver)
        old_node.once_identity_receivers.erase(receiver)
        if old_node.receivers.is_empty() and old_node.identity_receivers.is_empty() \
                and old_node.once_receivers.is_empty() and old_node.once_identity_receivers.is_empty():
            _nodes.erase(old_id)
    _init_message_node(new_id)
    var new_node: MessageNode = _nodes[new_id]
    var target_list: Array[Callable] = new_node.once_identity_receivers if was_once else new_node.identity_receivers
    if not target_list.has(receiver):
        target_list.append(receiver)
    _aliases[old_id] = new_id

## 顺着别名链解析出节点当前的真实 ID。
## 被谁用：unlisten。
static func _resolve_alias(id: String) -> String:
    var cur := id
    while _aliases.has(cur):
        cur = _aliases[cur]
    return cur


## ---------- 收发 ----------

## 把消息发给该 ID 的所有接收器（普通 → identity → 一次性 → 一次性身份），返回所有返回值（按登记顺序）。
## 同时把消息记在节点上（get_message 可取"上一次的消息"）。
## **遍历一律用快照（`duplicate()`）**：回调里可能**退订 / 重订**——"看某个东西的 UI"收到消息就重铺，
## 重铺会整批退订再订回来（见 UI_View.sync_listening）。边遍历边删会**跳过**它后面的接收器
## （实测：属性一览的重铺排在前面时，同一条广播上排在它后面的订阅收不到这一次消息）。
## 快照语义与下面"一次性接收器"那段一致：**回调里新注册的留到下一次广播**。
## 被谁用：MessageHub 的所有 send_*。没有该节点就返回空数组（没人听，不算错误）。
static func send(id: String, message: Variant) -> Array:
    if not _nodes.has(id):
        return []
    var node: MessageNode = _nodes[id]
    node.message = message
    var result := []
    for receiver in node.receivers.duplicate():
        result.append(receiver.call(message))
    for receiver in node.identity_receivers.duplicate():
        result.append(receiver.call(message))
    # 一次性接收器：**先摘下来再调**（回调里再注册同一个监听不会被误删），
    # 回调里新注册的一次性监听留到下一次广播（也就不会自我循环）。
    var once_list: Array[Callable] = node.once_receivers.duplicate()
    node.once_receivers.clear()
    for receiver in once_list:
        result.append(receiver.call(message))
    var once_identity_list: Array[Callable] = node.once_identity_receivers.duplicate()
    node.once_identity_receivers.clear()
    for receiver in once_identity_list:
        result.append(receiver.call(message))
    return result

## 取该 ID 上一次收到的消息（没发过/没节点都返回 null）。
## 被谁用：MessageHub 里"取上次消息"的接口。
static func get_message(id: String) -> Variant:
    if not _nodes.has(id):
        return null
    return _nodes[id]["message"]

## 拼节点 ID：各段用 "->" 连接（如 ["char","1","key","32"] → "char->1->key->32"）。
## 被谁用：MessageHub 拼各类消息的 ID；parse_ID 为逆操作。
static func format_ID(infos: Array[String]) -> String:
    return "->".join(infos)

## 拆节点 ID（"->" 分段）。
## 被谁用：MessageHub 里需要按 ID 段取参数的接收器。
static func parse_ID(id: String) -> Array[String]:
    var result: Array[String] = []
    result.assign(id.split("->"))
    return result
