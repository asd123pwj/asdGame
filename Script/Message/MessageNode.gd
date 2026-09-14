class_name MessageNode
extends BaseClass
## 消息节点：一个"接收方 ID"上的收件箱（见 Script/Message/Message.md）。
## 一条消息发给某个 ID 时，就是遍历这个节点的两个接收器列表逐个调用。
## 被谁用：MsgBus._nodes（按 ID 存节点）。

## 普通接收器：listen 时登记、unlisten 时移除，不随 identity 变化迁移。
## 被谁用：MsgBus.listen / unlisten / send。
var receivers: Array[Callable] = []
## 绑定到 identity 的接收器：与 receivers 一样参与广播，二者一起被 send 遍历。
## 唯一区别是 identity 换角色时，这些接收器会被迁到新角色对应的节点上
## （见 MsgBus.rebind_identity / _move_identity_receiver）。
var identity_receivers: Array[Callable] = []
## 最近一次发到这个节点的消息内容（"取上一次消息"用）。
## 被谁用：MsgBus.send（写）、MsgBus.get_message（读）。
var message: Variant = null
