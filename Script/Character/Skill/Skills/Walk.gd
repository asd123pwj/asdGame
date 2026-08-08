class_name Walk
extends SkillBase

# ----- Config -----

func _act(_char: Character, _delta: float, _config: Array) -> bool:
    _char.body.velocity = _config[0]
    _char.body.move_and_slide()
    return true