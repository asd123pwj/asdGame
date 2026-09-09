# Interaction · 子文件夹总结

## 定位
"交互系统"：依赖某状态满足后执行一个**动作**。Interactions 是具体动作类，多数最终落到"改角色属性/读取背包"。

## 文件（一层）
| 文件 | 作用 |
|---|---|
| `InteractionPreset.gd` | 一条交互预设(绑定实现+config+依赖状态)。`extends PresetRegister`。 |
| `Interactions.gd` | 每个角色的交互集合。`extends BaseClass`。 |
| `Interactions/` | 交互基类 + 各具体动作实现。 |

## InteractionPreset.gd 说明（Preset）
- 一条交互 = `name/interaction_name(实现类)/dependence_status(依赖状态)/config`。
- `_init` 里 `_get_interaction_by_name()`：按 `interaction_name` new 出 `Interaction_xxx` 实例并传 name/config。
- `listen(char_)`：监听 `dependence_status` satisfied → `interaction.interact(char_, target)`，target 取 `char_.statuses.get_latest_message(dependence_status)`；再广播 `Msg.send_interaction_act`。
- `unlisten(char_)`：取消监听。

## Interactions.gd 说明（集合）
- `_init(me, names[])` → `add_interaction`。
- `add/remove_interaction`、`check_exist(name)`：装/卸/查。

## Interactions/ 子目录（Base + 动作）
- **`InteractionBase.gd`（基类）**：持 `name/config`；提供通用属性影响工具——
  - `attack/heal/cost/practice`：把三个角色(source/compare/target)的属性比出差值作用到 target(改 `attrs`)，返回 `ChangeResult`。
  - `impact(...)`：核心实现，含 source/compare/target 取值、consume、方向/正负、最终 `target.attrs.set_level_cur`。
  - `interact(source, target)`：虚接口，由子类覆写。
- 各动作覆写 `interact`：
  - `Interaction_AddBuff`：给 target 加 config 指定的 buff。
  - `Interaction_Attack`：攻击(Strength-Defense→Health)，并发"练习"检测。
  - `Interaction_Heal`：治疗(Health 互比)，成功发检测。
  - `Interaction_CostHeal`：消耗式治疗(自身代价)。
  - `Interaction_TryHealSelf`：扫背包找可治疗物品。
  - `Interaction_Eat`：吃 target(判定 Healable)。
  - `Interaction_Practice`：让某属性"成长"(绕 BASE 随机)。
  - `Interaction_Rebirth`：复活(重置 Health CUR)。
  - `Interaction_DropOnDeath`：死亡掉落(读 DeadDrop 背包打印)。
  - `Interaction_SayChanged`：打印某属性"被谁/怎样"变化。
  - `Interaction_ScanInventory`：占位(空)。
