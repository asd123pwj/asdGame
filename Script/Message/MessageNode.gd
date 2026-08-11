class_name MessageNode
extends RefCounted

var receivers: Array[Callable]
var message: Variant

func _init():
    receivers = []
    message = null

func check_not_empty() -> bool:
    return receivers.size() > 0
