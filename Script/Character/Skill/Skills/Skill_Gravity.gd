class_name Skill_Gravity
extends SkillBase

# ----- Config -----

func _act(me: Character, _delta: float, _config: Array) -> bool:
    if not me.body.is_on_floor():
        me.body.velocity.y += Sys.sysCfg.gravity * _delta
    return true