# Status · 子文件夹总结

## 定位
"状态系统"：把一个或多个**条件(监听器)**监听的结果汇总成一个布尔状态 `satisfied`。Status 的实际用法是**监听**——它是全系统的事件判断源，被 Skill/Interaction 依赖触发。

## 文件
| 文件 | 作用 |
|---|---|
| `StatusPreset.gd` | 一条状态的预设定义(含各类监听器)。`extends PresetRegister`。 |
| `Statuses.gd` | 每个角色的状态集合。`extends BaseClass`。 |
| `StatusListener.gd`（.uid） | 监听器 `ListenType` 的描述(单条匹配规则)，见下。 |

## StatusPreset.gd 说明（Preset）
- 字段：`name/auto_reset(变化后自动复位)/match_any(任一满足即满足)/with_detect` + 6 类监听器数组(attrs/buffs/statuses/interactions/keys/time)。
- 监听器 `ListenType` = `match_type(比较符) + name(监听对象) + thres(阈值)`。attrs 支持 Changed/>/</Base*/AnyChanged 等；buffs Present/Absent；statuses Satisfied/Unsatisfied；interactions Present/Absent/Act；keys 按下抬起；time 时间推进；with_detect 用外部检测信号。
- `listen(char_)`：按监听器类型 `Msg.listen_*` 注册触发器，实时把各触发器真值写进 `_xxx_triggers[char_]`。
- `execute(char_, force)`：汇总各触发器真值(按 match_any 取与/或) → 得 `satisfied`；满足/解除时发 `Msg.send_status_satisfied/unsatisfied`。
- `char_init_done(char_)`：初始化完成后强制 `execute` 一次，校准初始状态。
- `get_latest_message`：返回最近一次触发收到的消息(供交互取 target)。
- 供谁调用：**被 SkillPreset / InteractionPreset 监听**某状态满足/解除来触发自身行为；也供 `Interaction` 里判断(如 check_satisfied("Healable"))。

## Statuses.gd 说明（集合）
- `_init(me, status_names[])`：按名字 `add_status` 把状态装给角色。
- `add/remove_status`：装/卸状态(内部调 preset.listen/unlisten)，广播 add/remove。
- `check_satisfied(name)`：查该状态当前是否满足。
- `check_exist(name)`：是否已安装。
- `get_latest_message(name)`：取该状态最近消息。
