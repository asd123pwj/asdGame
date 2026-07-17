class_name MsgBus
extends RefCounted

static var _nodes: Dictionary[String, MessageNode] = {}   

static func _init_message_node(id: String) -> void:
    if _nodes.has(id):
        return
    _nodes[id] = MessageNode.new()

static func listen(id: String, receiver: Callable) -> String:
    if not _nodes.has(id):
        _init_message_node(id)
    _nodes[id].receivers.append(receiver)
    return id

static func unlisten(id: String, receiver: Callable) -> void:
    if not _nodes.has(id):
        return
    _nodes[id].receivers.erase(receiver)
    if _nodes[id].receivers.is_empty():
        _nodes.erase(id)

static func send(id: String, message: Variant) -> Enums.Code:
    if not _nodes.has(id):
        return Enums.Code.NOT_FOUND
    _nodes[id]["message"] = message
    for receiver in _nodes[id].receivers:
        receiver.call(message)
    return Enums.Code.OK

static func get_message(id: String) -> Variant:
    if not _nodes.has(id):
        return null
    return _nodes[id]["message"]

static func format_ID(infos: Array[String]) -> String:
    return "->".join(infos)