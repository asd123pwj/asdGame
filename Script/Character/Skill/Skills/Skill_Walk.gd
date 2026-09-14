class_name Skill_Walk
extends SkillBase
## 行走技能：把水平速度直接设成配置值（谁负责左右方向由状态层的 config 决定）。
## 被谁用：SkillPreset（skill_name = "Skill_Walk"）。

## 设水平速度 = _config[0]。
## 被谁用：SkillBase.act（每物理帧）。
func _act(me: Character, _delta: float, _config: Array) -> bool:
    me.body.velocity.x = _config[0]
    return true
