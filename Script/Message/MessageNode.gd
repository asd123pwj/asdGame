class_name MessageNode
extends BaseClass

var receivers: Array[Callable] = []
## 绑定到 identity 的接收器：与 receivers 一样参与广播，二者一起被 send 遍历。
## 唯一区别是 identity 换角色时，这些接收器会被迁到新角色对应的节点上
## （见 MsgBus.rebind_identity / _move_identity_receiver）。
var identity_receivers: Array[Callable] = []
var message: Variant = null
