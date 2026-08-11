class_name BehaviorBase
extends RefCounted


var class_name_: String

func _init() -> void:
    var script: Script = get_script()
    class_name_ = script.get_global_name()

func act(_char: Character, _config: Array) -> Enums.Code:
    return Enums.Code.NULL