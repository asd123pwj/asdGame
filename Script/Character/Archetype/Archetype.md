# Archetype · 子文件夹总结

## 定位
"种族/角色定义"的组合根：描述一个角色由哪些模块预设组成（不含模块内部实现）。只存各模块的**预设名数组**，不落地任何能力本身。

## 文件
| 文件 | 作用 |
|---|---|
| `Archetype.gd` | 单个种族配置。`extends PresetRegister`。 |

## Archetype.gd 说明
- 字段：`name` + `buffs/statuses/interactions/skills/collisions/inventories/bodies/packages`（均为预设名 String 数组）。
- `_init(config)`：把 config（来自 `Config/Character/Archetype/` 配置文件）读入，注册进 `static _we[name]`。
- `static get_(name)`：查注册表；首次查时若含 `packages`，把被引用 archetype 的各数组并入本角色并**去重**（`_deduplicate`），懒展开。
- 供谁调用：仅 `Character._init_from_archetype` 读取，作为整棵角色的装配清单。
