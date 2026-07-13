class_name ChangeResult
extends RefCounted


var code: Enums.Code
var ori: int
var new: int
var offset: int

func _init(code: Enums.Code, ori: int, new: int, offset: int) -> void:
	self.code = code
	self.ori = ori
	self.new = new
	self.offset = offset
