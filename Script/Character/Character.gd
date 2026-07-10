class_name Character
extends RefCounted


var _char_name: String
var _attr_states: Dictionary[String, AttributeState]

func _init(name: String) -> void:
    self._char_name = name
    _init_attr_states()

func _init_attr_states() -> void:
    for name in ["Attack", "Defense", "Health"]:
        _attr_states[name] = AttributeState.new(name)

func get_name() -> String:
    return self._char_name

func get_attr_state(name: String) -> AttributeState:
    return self._attr_states[name]

func get_attr_states_name() -> Array[String]:
    return self._attr_states.keys()