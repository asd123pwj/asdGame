class_name Character
extends RefCounted


var name: String
var attr: Attribute
var ID: int = get_instance_id()

func _init(name: String, attr_set_name: String) -> void:
    self.name = name
    _init_attr(attr_set_name)

func _init_attr(attr_set_name: String) -> void:
    var attr_set: AttributeSet = AttributeSet.new_.call([attr_set_name])
    attr = Attribute.new(self, attr_set.types, attr_set.buffs)



    