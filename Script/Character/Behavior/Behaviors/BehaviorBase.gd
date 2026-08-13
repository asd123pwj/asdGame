class_name BehaviorBase
extends RefCounted


@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()

func _init() -> void:
    pass

func act(_char: Character, _config: Array) -> Enums.Code:
    return Enums.Code.NULL