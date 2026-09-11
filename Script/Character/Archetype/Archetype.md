# Archetype · 子文件夹总结

## 定位
"种族/角色定义"的组合根：描述一个角色由哪些模块预设组成（不含模块内部实现）。只存各模块的**预设名数组**，不落地任何能力本身。

## 文件
| 文件 | 作用 |
|---|---|
| `Archetype.gd` | 单个种族配置。`extends PresetRegister`。 |

## Archetype.gd 说明
- 字段：`name` + `buffs/statuses/interactions/skills/collisions/inventories/shortcuts/bodies/packages`（读取后统一存为**预设名 String 数组**，**各数组都可为空**）。
- `bodies` 为空 → 该角色**无 body**：`Character.ensure_body()` 返回 `null`，可用作"纯逻辑角色"(如持有按键状态的 sys 角色)。
- **元素两种写法（内联 / 引用）**：数组中每个元素既可是
  - **字符串** → 视为"已存在的预设名"，直接用（如 `"Right"`）；
  - **字典 / 列表** → 视为该预设的**内联配置**，按字段对应的类现场 `new` 并注册，再取其 `name` 存入。字段 → 类的映射见 `_field_class`：`buffs→BuffPreset`、`statuses→StatusPreset`、`interactions→InteractionPreset`、`bodies→BodyPreset`、`skills→SkillPreset`、`collisions→CollisionPreset`、`inventories→InventoryPreset`、`shortcuts→SystemShortcutPreset`、`packages→Archetype`。
  - 取值规则：**字典**取 `item["name"]`；**列表**取 `item[0]`（即 `_init` 的首参）。
  - 这样"只在一处出现"的模块（如系统专用状态）可直接内联在 archetype 里，不必另建配置文件。
  - **重名保护**：内联项若与已有同名预设冲突，`push_error` 报错并跳过（避免静默覆盖），便于发现"忘记已创建"。
- `_init(config)`：把 config（来自 `Config/Character/Archetype/` 配置文件）读入，注册进 `static _we[name]`。
- `static get_(name)`：查注册表；首次查时若含 `packages`，把被引用 archetype 的各数组并入本角色并**去重**（`_deduplicate`），懒展开。
- 供谁调用：仅 `Character._init_from_archetype` 读取，作为整棵角色的装配清单。

## 示例（内联 = 引用）
下列三者等价，都会得到一个名为 `输入监控` 的 archetype，含四个状态：
```gdscript
# A. 全部内联（推荐：系统专用内容只写这一处）
{ "name": "输入监控", "statuses": [
    { "name": "Right", "match_any": true, "keys": [[KEY_RIGHT, Enums.KeyStatus.DOWN]] },
] }

# B. 部分内联 + 部分引用
{ "name": "输入监控", "statuses": [
    "SomeSharedStatus",                                   # 已有：直接用名字
    { "name": "Right", "match_any": true, "keys": [...] }, # 内联：现场创建
] }
```
注：`Config/Character/Status/StatusPreset_Input.gd`、`SystemShortcutPreset_Input.gd` 中的同名项已**改为内联**写在 `Archetype_System.gd`，原文件已注释保留作参考。
