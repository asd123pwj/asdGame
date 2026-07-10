class_name MessageBus
extends RefCounted

var _nodes: Dictionary[String, MessageNode] = {}   

func _init_message_node(id: String) -> void:
    if _nodes.has(id):
        return
    _nodes[id] = MessageNode.new()

func add_receiver(id: String, receiver: Callable) -> void:
    if not _nodes.has(id):
        _init_message_node(id)
    _nodes[id].receivers.append(receiver)

func send(id: String, message: Variant) -> void:
    if not _nodes.has(id):
        _init_message_node(id)
    _nodes[id]["message"] = message
    for receiver in _nodes[id].receivers:
        receiver.call(message)

func send2COMMAND(message: Variant) -> void:
    send("COMMAND", message)

func get_message(id: String) -> Variant:
    if not _nodes.has(id):
        return null
    return _nodes[id]["message"]