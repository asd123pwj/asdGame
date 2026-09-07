class_name Skill_Walk
extends SkillBase

func _act(me: Character, _delta: float, _config: Array) -> bool:
    me.body.velocity.x = _config[0]
    return true