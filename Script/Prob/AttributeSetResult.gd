class_name AttributeSetResult
extends RefCounted


var code: Enums.Code
var level_ori: int
var level_new: int
var level_offset: int

func _init(code: Enums.Code, level_ori: int, level_new: int, level_offset: int) -> void:
	self.code = code
	self.level_ori = level_ori
	self.level_new = level_new
	self.level_offset = level_offset