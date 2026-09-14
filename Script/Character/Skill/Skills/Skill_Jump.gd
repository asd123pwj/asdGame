class_name Skill_Jump
extends SkillBase
## 跳跃技能：把垂直速度设成"向上"的配置值（一次性脉冲，通常配在很短的状态里）。
## 被谁用：SkillPreset（skill_name = "Skill_Jump"）。

## 设垂直速度 = -_config[0]（Godot 的 y 向下为正，故取负表示向上跳）。
## 被谁用：SkillBase.act（每物理帧）。
func _act(me: Character, _delta: float, _config: Array) -> bool:
    # Godot以下为正半轴，我喜欢上面正半轴，因此取负号，速度为正向上跳跃
    me.body.velocity.y = -_config[0]
    return true
