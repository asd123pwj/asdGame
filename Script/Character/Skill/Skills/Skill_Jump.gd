class_name Skill_Jump
extends SkillBase

func _act(me: Character, _delta: float, _config: Array) -> bool:
    # Godot以下为正半轴，我喜欢上面正半轴，因此取负号，速度为正向上跳跃
    me.body.velocity.y = -_config[0]
    return true