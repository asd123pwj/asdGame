class_name SkillBase
extends RefCounted

@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()


func _init() -> void:
    pass

func in_queue(_char: Character, _config: Array) -> void:
    _char.skills.skill_queue[self] = _config

func out_queue(_char: Character) -> void:
    _char.skills.skill_queue.erase(self)

func act(_char: Character, _delta: float, _config: Array) -> bool:
    if _act(_char, _delta, _config):
        MsgHubChar.send_behavior_act(_char, CLASS_NAME)
        return true
    return false

func _act(_char: Character, _delta: float, _config: Array) -> bool:
    return true