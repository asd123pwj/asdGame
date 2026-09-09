# Collision · 子文件夹总结

## 定位
"碰撞检测系统"：为角色建 Area2D 探测区，物体进入/离开时广播消息，供状态/交互判定(如接触即触发某状态)。

## 文件（一层）
| 文件 | 作用 |
|---|---|
| `CollisionPreset.gd` | 一条碰撞预设(绑定碰撞实现+config)。`extends PresetRegister`。 |
| `Collisions.gd` | 每个角色的碰撞集合。`extends BaseClass`。 |
| `Collisions/` | 碰撞实现。 |

## CollisionPreset.gd 说明（Preset）
- 一条碰撞 = `name/collision_name(实现类 class_name)/config`。
- `_init` 里 `_get_collision_by_name()`：按 `collision_name` 找到实现类脚本。
- `static get_(name)`：查注册表。
- `listen(char_)`：`collision.new(char_, name, config)` 为角色实例化一个碰撞对象，存进 `collision_objs[char_]`。

## Collisions.gd 说明（集合）
- `_init(me, names[])` → `add_collision`。
- `add/remove_collision`：装/卸(内部 preset.listen/unlisten)，广播 add/remove。
- `check_collision(name)`：查是否已装。

## Collisions/ 子目录（实现）
- **`Collision_Area.gd`**：建 Area2D+CollisionShape(Circle) 挂到 `me.body`。
  - `_on_body_entered/exited(body)`：若 `body` 带 `meta("character")` 反查是角色；一律广播 `Msg.send_collision_enter/exit(me, name, body)`。
  - 该消息被 `StatusPreset.with_detect` 等监听，作为状态触发源。
