class_name Skill_Damping
extends SkillBase
## 阻尼技能：地面摩擦/撞墙时的速度衰减（配置 [是否摩擦型, 阻力系数 Vector2]）。
## 摩擦型：阻力 = 当前速度 × 系数（并保证不低于 sysCfg.min_damping_velocity，避免永远停不下来）。
## 被谁用：SkillPreset（skill_name = "Skill_Damping"）。

## 逐轴（x 贴地、y 贴墙）衰减速度；速度小于阻力就直接归零。
## 被谁用：SkillBase.act（每物理帧）。
func _act(me: Character, _delta: float, _config: Array) -> bool:
    # 摩擦阻力为定值，空气阻力随速度而变化
    var is_friction: bool = _config[0]
    var damping: Vector2 = Vector2(_config[1].x, _config[1].y)
    
    # x轴阻力
    if is_friction and me.body.is_on_floor() and me.body.velocity.x != 0:
        var dir = 1 if me.body.velocity.x >= 0 else -1
        var x_abs: float = abs(me.body.velocity.x)
        if is_friction:
            damping.x = x_abs * damping.x
            if damping.x < Sys.sysCfg.min_damping_velocity.x:
                damping.x = Sys.sysCfg.min_damping_velocity.x
        if x_abs < damping.x:
            me.body.velocity.x = 0
        else:
            me.body.velocity.x -= dir * damping
    # y轴阻力
    if is_friction and me.body.is_on_wall() and me.body.velocity.y != 0:
        var dir = 1 if me.body.velocity.y >= 0 else -1
        var y_abs: float = abs(me.body.velocity.y)
        if is_friction:
            damping.y = y_abs * damping.y
            if damping.y < Sys.sysCfg.min_damping_velocity.y:
                damping.y = Sys.sysCfg.min_damping_velocity.y
        if y_abs < damping.y:
            me.body.velocity.y = 0
        else:
            me.body.velocity.y -= dir * damping

    return true
