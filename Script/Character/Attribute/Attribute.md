# Attribute · 子文件夹总结

## 定位
"属性系统"：把 Buff 当作对属性的**加成**，统一计算角色各类属性值（如 Health 有 BASE/CUR/MIN/MULTIPLIER）。Buff 实际作用是**叠加属性**。

## 文件
| 文件 | 作用 |
|---|---|
| `BuffPreset.gd` | 一条加成(Buff)的预设定义。`extends PresetRegister`。 |
| `Attributes.gd` | 每个角色的属性集合/管理器，负责装 buff 并算属性值。`extends BaseClass`。 |

## BuffPreset.gd 说明（Preset）
- 一条 Buff = `name/category(类别)/value_type(BASE|CUR|MIN|MULTIPLIER)/value/method(加减乘除设置)/max_uses`。
- `static get_(name)`：查注册表（数据来自 `Config/Character/Attribute/`）。
- `apply(value, char_)`：按 method 对传入属性值应用加成；`value` 可为 int 或引用另一属性的 String。
- `consume(char_)`：累计使用次数，超 `max_uses` 则让 `char_.attrs.remove_buff` 移除自身。

## Attributes.gd 说明（集合）
- 结构：`buffs`(Category→ValueType→BuffName→Preset)、`attributes`(Category→ValueType→值)。
- `add/remove/check_buff`：装/卸加成，装卸时重算属性并广播 `Msg.send_buff_add/remove`。
- `init_attribute`：按类型算值——BASE 从世界默认 + 各 BASE 加成；MULTIPLIER 随机权重；CUR 依赖 BASE×MULTIPLIER 后再加 CUR 加成；最终过 MIN 判定。
- `get_(category, type, ...)`：取值，未算则惰性 `init_attribute`；`dynamic` 时带随机并 `consume_buffs`。
- `set_level_cur`：改 CUR 值，返回 `ChangeResult`，并广播 `Msg.send_attr_changed`。
- `consume_buff(s)`：把某类加成"用掉"(次数)。
- `get_changed_by_how/who`：记录值被谁/怎么改的（供 SayChanged 打印）。
- 供谁调用：`InteractionBase.impact/attack/heal/cost`(改值)、`StatusPreset`(监听值)、`BuffPreset.consume`、角色死亡/复活等。
