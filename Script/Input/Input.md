# Input · 输入系统

## 定位
把引擎原始输入(键/鼠标)翻译成"按键状态"事件发到消息总线；支持"组合键"序列识别成整体按键。

## 文件
| 文件 | 作用 |
|---|---|
| `InputSystem.gd` | `InputSys`：接收引擎输入 → 记录按键状态 → 发消息。 |
| `InputCombo.gd` | `InputCombo`：把一串按键序列识别为一个组合键事件。 |
| `PointDetect.gd` | `PointDetect`：监控指针目标(UI/角色/地图)，把交互键派发到命中目标。 |

## InputSystem.gd（InputSys，extends BaseClass）
- 静态状态：`mouse_position`、`on_edit`、`keys_downing`(当前按住集合)。
- `static _input(event)`：被 `Sys._input` 调；区分 Key/MouseButton/MouseMotion，按键按下/抬起调 `_send_key_status`。
- `static _process(delta)`：对按住中的 key 每帧 `Msg.send_key_down`。
- `static _send_key_status(key, isDown)`：按下→(首按则)入集合 + `Msg.send_key_first_down`；抬起→出集合 + `Msg.send_key_first_up`。
- 供谁调用：被 `Sys._input/_process` 转发；`keys_downing` 被 InputCombo/其它读。

## InputCombo.gd（extends BaseClass）
- `_init(sequence, interval)`：注册一段组合键序列并监听其按键。
- `static add_if_not_exist(sequence)`：Msg._listen_input 遇 Array 时自动为其建监听。
- `_listen/_unlisten`：为序列每键挂 `key_down/first_down/first_up` 回调。
- 组合判定：`_check_combo` 按顺序、deadline(间隔)内连续输入，完整匹配则当整体 `Msg.send_key_first_down(sequence)`；释放则 `send_key_first_up`。
- `static unlisten(sequence)`：移除。
- 供谁调用：`Msg`(MessageHub) 的 input 分支(Array 键走这里)；需要"连招/组合键"的监听方。

## PointDetect.gd（extends BaseClass）
- 职责：监控指针目标，把交互键派发到命中目标（UI 走 UI 操作，角色/地图暂忽略，留待扩展）。
- **只提供执行函数，不监听按键**：按键→状态→SystemShortcut→指令 的链路由 `Character` 的 Status/SystemShortcut 声明（见 `Character/SystemShortcut/SystemShortcut.md`），此处不再 `Msg.listen_key_*`。
- 静态状态：`hover_ui`(指针下 UI) / `hover_char`(指针下角色) / `map_position`(指针地图格，逻辑坐标 y 向上) / `dragging_ui`(拖动中 UI)。
- **按需计算**（不再每帧）：`static update_targets()` 按 `InputSys.mouse_position` 刷新 `hover_ui/hover_char/map_position`，仅在真正派发前调用。
- 执行函数（静态，可被指令系统按 `PointDetect.xxx` 调用）：
  - `pointer_down()`：`update_targets()` 后命中 UI 调 `ui.on_pointer_down()`（锁定 `dragging_ui`）。
  - `pointer_move()`：无拖动则直接返回；否则 `update_targets()` + `ui.on_pointer_move()`（拖动跟随，天然支持连按/长按）。
  - `pointer_up()`：`ui.on_pointer_up()`，清 `dragging_ui`。
  - `submit()`：`update_targets()` 后 `ui.on_submit()`。
- 命中判定：UI 按 `Sys.uiSys.uis` 加入顺序取最上层、`control.get_global_rect()` 矩形命中；角色按身体 `CollisionShape2D` 矩形；地图按世界坐标 / `TileSpritePreset.tileset.tile_size` 换算（y 取反）。
- 驱动链路：`StatusPreset_Pointer` 定义按键状态（Pointer Down/Hold/Up、Submit）→ `SystemShortcutPreset_Pointer` 声明"状态满足→`PointDetect.pointer_down` 等指令"→ 满足时 `Msg.send_cmd`。输入全部来自 `InputSys` 的 `Msg` 消息，不用引擎 `gui_input`。
