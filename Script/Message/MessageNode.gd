class_name MessageNode
extends RefCounted

var receivers: Array[Callable]
var message: Variant

func _init():
    receivers = []
    message = null