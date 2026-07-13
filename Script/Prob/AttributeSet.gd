class_name AttributeSet
extends PresetRegister


""" ----- individual ----- """
var name: String
var types: Array[String]
var buffs: Array[String]

""" ----- Global ----- """
static var new_: Callable

func _init(name: String, types: Array=[], buffs: Array=[]) -> void:
    self.name = name
    self.types.assign(types.filter(func(x): return x is String))
    self.buffs.assign(buffs.filter(func(x): return x is String))
