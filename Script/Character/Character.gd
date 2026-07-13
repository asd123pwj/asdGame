class_name Character
extends RefCounted


var name: String
var attr: AttributeState

func _init(name: String, attr_set_name: String) -> void:
    self.name = name
    _init_attr_states(attr_set_name)

func _init_attr_states(attr_set_name: String) -> void:
    var attr_set: AttributeSet = AttributeSet.new_.call([attr_set_name])
    attr = AttributeState.new(self, attr_set.types, attr_set.buffs)



    