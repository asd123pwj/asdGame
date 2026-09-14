class_name Skill_Gravity
extends SkillBase
## 重力技能：不在地面时按 sysCfg.gravity 累积垂直速度（常驻队列）。
## 被谁用：SkillPreset（skill_name = "Skill_Gravity"）。

## 不在地面就给垂直速度加速度（_delta 保证与帧率无关）。
## 被谁用：SkillBase.act（每物理帧）。
func _act(me: Character, _delta: float, _config: Array) -> bool:
    if not me.body.is_on_floor():
        me.body.velocity.y += Sys.sysCfg.gravity * _delta
    return true
