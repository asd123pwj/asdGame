# Input · 输入系统

## 定位
把引擎原始输入(键/鼠标)翻译成"按键状态"事件发到消息总线；支持"组合键"序列识别成整体按键。

## 文件
| 文件 | 作用 |
|---|---|
| `InputSystem.gd` | `InputSys`：接收引擎输入 → 记录按键状态 → 发消息。 |
| `InputCombo.gd` | `InputCombo`：把一串按键序列识别为一个组合键事件。 |
| `PointerDetect.gd` | `PointerDetect`：监控指针目标(UI/角色/地图)，把交互键派发到命中目标。 |

## InputSystem.gd（InputSys，extends BaseClass）
- 静态状态：`mouse_position`、`mouse_delta`(本帧累计指针位移，帧末清零)、`on_edit`、`keys_holding`(当前按住集合)。
- `static _input(event)`：被 `Sys._input` 调；区分 Key/MouseButton/MouseMotion，按键按下/抬起调 `_send_key_status`。
- `static _process(delta)`：对按住中的 key 每帧 `Msg.send_key_hold`（按键类状态的消费发生在这里）。
- `static end_frame()`：**帧末把 `mouse_delta` 清零**，由 `Sys._process` 最后调用。
- **位移的时间基准是"帧"**（一帧 = `Sys._process` 的范围）：
  `_input` 累计 → `InputSys._process`（按键类消费）→ `TimeSys._process`（Tick 类消费，**拖拽走这里**）→ `end_frame()` 清零。
  一帧内多个 MouseMotion 事件累加，拖拽类指令按帧消费一次，因此指针停下时位移为 (0,0)（不漂），快移时拿到本帧总位移（不丢距离）。
  **清零只能在帧末**：若放在 `InputSys._process` 里，晚于它才被 Tick 触发的拖拽就永远读到 (0,0)。
- `static _send_key_status(key, isDown)`：按下→(首按则)入集合 + `Msg.send_key_press`；抬起→出集合 + `Msg.send_key_release`。
- 鼠标移动：`keys_holding` 非空（拖拽中）才 `Msg.send_pointer_move()`，单纯悬停不发——"Pointer Move" 状态的语义即"按住拖动中的移动"。
- 供谁调用：被 `Sys._input/_process` 转发；`keys_holding` 被 InputCombo/其它读。

## InputCombo.gd（extends BaseClass）
- `_init(sequence, interval)`：注册一段组合键序列并监听其按键。
- `static add_if_not_exist(sequence)`：Msg._listen_input 遇 Array 时自动为其建监听。
- `_listen/_unlisten`：为序列每键挂 `hold/press/release` 回调。
- 组合判定：`_check_combo` 按顺序、deadline(间隔)内连续输入，完整匹配则当整体 `Msg.send_key_press(sequence)`；释放则 `send_key_release`。
- `static unlisten(sequence)`：移除。
- 供谁调用：`Msg`(MessageHub) 的 input 分支(Array 键走这里)；需要"连招/组合键"的监听方。

## PointerDetect.gd（extends BaseClass）
- 职责：监控指针目标，把交互键派发到命中目标（UI 走 UI 操作，角色/地图暂忽略，留待扩展）。
- **只提供执行函数，不监听按键**：按键→状态→SystemShortcut→指令 的链路由 `Character` 的 Status/SystemShortcut 声明（见 `Character/SystemShortcut/SystemShortcut.md`），此处不再 `Msg.listen_key_*`。
- 静态状态：`hover_ui`(指针下 UI) / `hover_char`(指针下角色) / `map_position`(指针地图格，逻辑坐标 y 向上)。
- **按需计算**：`static update_targets()` 按 `InputSys.mouse_position` 刷新 `hover_ui/hover_char/map_position`；hover 变化时对新旧 UI 派发 `QName.pointer_enter / QName.pointer_exit`（两个内置事件名，放在 Config/QuickName.gd）。
- 执行函数只有一个：`static key(status_name)`（指令串 `PointerDetect.key "状态名"`）：
  - **不区分 press/hold/release/move，也不涉及键位**——"哪个状态满足了"由状态层判定，这里只把状态名当事件名派发。
  - **派发目标**：当前 hover 的 UI —— 指针不锁定（按住后指针会离开元素，所以"按住期间的事"不走这里）。
  - 命中刷新由每帧 Tick 的 `update_targets` 负责（不再在派发前重复刷新）。
  - 命中 UI 时调 `ui.on_event(状态名)`，UI 侧按状态名等值匹配 `config["events"]` 里的指令。
  - **"按住期间每帧要做的事"不走这里**：走 `AutoSys`（`Script/Auto/Auto.md`：挂在状态上、每帧执行指令、状态不满足自动删）——指针层不参与，也就不需要捕获机制。
- 命中判定：UI 按 `UiSys.uis` 加入顺序取最上层、`control.get_global_rect()` 矩形命中；角色按身体 `CollisionShape2D` 矩形；地图按世界坐标 / `TileSpritePreset.tileset.tile_size` 换算（y 取反）。
- 驱动链路：`StatusPreset_Pointer` 定义按键状态（Pointer Press/Hold/Release、Submit）→ `SystemShortcutPreset_Pointer` 声明"状态满足→`PointerDetect.key` 指令"→ 满足时 `Msg.send_cmd`。输入全部来自 `InputSys` 的 `Msg` 消息，不用引擎 `gui_input`。
