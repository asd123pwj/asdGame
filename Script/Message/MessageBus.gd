class_name MsgBus
extends BaseClass

static var _nodes: Dictionary[String, MessageNode] = {}   

## 迁移别名：旧节点 ID -> 新节点 ID。identity 接收器被迁走后，调用方手里仍握着
## 监听时返回的旧 ID，unlisten 时顺着别名链找到当前节点，避免取消不掉而泄漏。
static var _aliases: Dictionary[String, String] = {}

## 绑定到 identity 的接收器登记：identity -> [[当前节点ID, receiver, 节点ID工厂], ...]
## identity 换角色时按工厂算出新节点，把接收器迁过去（见 rebind_identity）。
static var _identity_bindings: Dictionary[String, Array] = {}

static func _init_message_node(id: String) -> void:
    if _nodes.has(id):
        return
    _nodes[id] = MessageNode.new()

## identity_bound 为 true 时记入 identity_receivers（同样参与广播，identity 变更时会迁移）。
static func listen(id: String, receiver: Callable, identity_bound: bool = false) -> String:
    if not _nodes.has(id):
        _init_message_node(id)
    if identity_bound:
        _nodes[id].identity_receivers.append(receiver)
    else:
        _nodes[id].receivers.append(receiver)
    return id

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
    if node.receivers.is_empty() and node.identity_receivers.is_empty():
        _nodes.erase(real_id)


## ---------- identity 接收器 ----------

## 把 receiver 登记为"绑定到 identity"：identity 换角色时由 rebind_identity 迁移。
## node_id 为当前所在节点；factory(char_) 产出该接收器在新角色下应处的节点 ID。
static func bind_identity_receiver(identity: String, node_id: String, receiver: Callable, factory: Callable) -> void:
    if not _identity_bindings.has(identity):
        _identity_bindings[identity] = []
    _identity_bindings[identity].append([node_id, receiver, factory])

## identity 出现/换角色：把绑定到它的接收器从旧节点迁到该角色对应的新节点。
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

## 把 receiver 从 old_id 的 identity_receivers 搬到 new_id 的 identity_receivers。
static func _move_identity_receiver(old_id: String, new_id: String, receiver: Callable) -> void:
    if _nodes.has(old_id):
        var old_node: MessageNode = _nodes[old_id]
        old_node.identity_receivers.erase(receiver)
        if old_node.receivers.is_empty() and old_node.identity_receivers.is_empty():
            _nodes.erase(old_id)
    _init_message_node(new_id)
    if not _nodes[new_id].identity_receivers.has(receiver):
        _nodes[new_id].identity_receivers.append(receiver)
    _aliases[old_id] = new_id

## 顺着别名链解析出节点当前的真实 ID。
static func _resolve_alias(id: String) -> String:
    var cur := id
    while _aliases.has(cur):
        cur = _aliases[cur]
    return cur


## ---------- 收发 ----------

static func send(id: String, message: Variant) -> Array:
    if not _nodes.has(id):
        return []
    _nodes[id]["message"] = message
    var result := []
    for receiver in _nodes[id].receivers:
        result.append(receiver.call(message))
    for receiver in _nodes[id].identity_receivers:
        result.append(receiver.call(message))
    return result

static func get_message(id: String) -> Variant:
    if not _nodes.has(id):
        return null
    return _nodes[id]["message"]

static func format_ID(infos: Array[String]) -> String:
    return "->".join(infos)

static func parse_ID(id: String) -> Array[String]:
    var result: Array[String] = []
    result.assign(id.split("->"))
    return result
