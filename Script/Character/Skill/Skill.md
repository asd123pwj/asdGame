# Skill · 子文件夹总结

## 定位
"技能系统"：一种**每物理帧被驱动**的角色行为(改 body.velocity 等)。由某"依赖状态"满足才进入行为队列。

## 文件
| 文件 | 作用 |
|---|---|
| `SkillPreset.gd` | 一条技能的预设定义(绑定实现+配置+依赖状态)。`extends PresetRegister`。 |
| `Skills.gd` | 每个角色的技能集合/队列驱动器。`extends BaseClass`。 |
| `Skills/SkillBase.gd` | 技能基类(通用入/出队 + act 包装)。 |
| `Skills/Skill_Walk.gd` | 移动：设 x 速度。 |
| `Skills/Skill_Gravity.gd` | 重力：累加 y 速度。 |
| `Skills/Skill_Jump.gd` | 跳跃：按下一次性设向上速度。 |
| `Skills/Skill_Damping.gd` | 阻尼：对 x/y 阻力衰减(定值摩擦+随速空气阻力)。 |

## SkillPreset.gd 说明（Preset）
- 一条技能 = `name/skill_name(实现类 class_name)/dependence_status(依赖状态)/config(给实现的参数)`。
- `_init` 里 `_get_skill_by_name()`：按 `skill_name` 从全局类表 new 出对应 `Skill_xxx` 实例。
- `static get_(name)`：查注册表。
- `listen(char_)`：监听 `dependence_status` 的 **satisfied→`skill.in_queue`**、**unsatisfied→`skill.out_queue`**。
- `unlisten(char_)`：取消注册的监听。

## Skills.gd 说明（集合/队列）
- `_init(me, skill_names[])`：`add_skill` 把技能装给角色。
- `add/remove_skill`：装/卸(内部 preset.listen/unlisten)。
- `skill_queue`(SkillBase→config)：待驱动队列。
- `physics_process(delta)`：对队列每个 `skill.act(me, delta, config)`，最后 `me.body.move_and_slide()`。被 `Character.physics_process` 转发。
- `check_skill`：查是否已装。

## Skills/ 子目录（Base + 实现）
- `SkillBase.gd`：`in_queue/out_queue`(登记进 `char.skills.skill_queue`)；`act` 调虚方法 `_act` 成功后广播 `Msg.send_skill_act`。
- 各 `Skill_xxx`：覆写 `_act(me, delta, config) -> bool`，直接改 `me.body.velocity`；`config` 为预设传来的参数数组(如走速、阻尼系数)。
