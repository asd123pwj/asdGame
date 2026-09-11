# Body · 子文件夹总结

## 定位
"身体/物理实体系统"：按预设的精灵图，为角色创建可视 + 可碰撞的 `CharacterBody2D` 节点。

## 文件
| 文件 | 作用 |
|---|---|
| `BodyPreset.gd` | 一个身体预设(名字 + 精灵图路径)。`extends PresetRegister`。 |

## BodyPreset.gd 说明（Preset）
- 一条身体 = `name/sprite_path`。
- `_init(name, sprite_path)`：注册进 `static _we[name]`（数据来自 `Config/Character/Body/`）。
- `static get_(name)`：查注册表。
- `create() -> CharacterBody2D`：按精灵图建身体——
  1. 建 `CharacterBody2D`
  2. 加 `Sprite2D`(载入精灵图)
  3. 加 `CollisionShape2D`(矩形，尺寸=精灵)
  4. 挂到 `current_scene`
  - 返回 body。
- 供谁调用：`Character.ensure_body`(延后生成：按 `archetype.bodies[0]` 取预设建 body，未配 `bodies` 则留空返回 `null`)；`body` 之后设 `meta("character", self)` 供碰撞反查。
