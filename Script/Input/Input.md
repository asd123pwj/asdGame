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
- 静态状态：`mouse_position`、`mouse_delta`(本帧累计指针位移，帧末清零)、`edit_ui`(正在编辑的输入框 UI，null = 没在编辑)、`keys_holding`(当前按住集合)。
- `edit_ui`：**正在编辑输入的 UI**（`UIInteract_Edit.begin_edit` 登记，提交 / 被关掉 / 点别处时清空）⇒ `_input` 里跳过按键翻译，打的字不会顺手触发 UI 指令或状态；**只有回车例外**——翻成 `QName.input_submit` 事件派给 `edit_ui`，于是"回车提交"也走在唯一输入链路上。
- `static _input(event)`：被 `Sys._input` 调；区分 Key/MouseButton/MouseMotion，按键按下/抬起调 `_send_key_status`（`edit_ui` 非空时不翻译按键，只把回车翻成提交事件）。
- `static end_edit()`：清掉 `edit_ui` 并释放控件焦点（由 `UIInteract.end_edit` 命令、以及 `PointerDetect.key` 开头的"点别处"调）。
- `static _process(delta)`：对按住中的 key 每帧 `Msg.send_key_hold`（按键类状态的消费发生在这里）。
- `static _clear_mouse_delta()`：**帧末把 `mouse_delta` 清零**——由 `_process` 用 `call_deferred` 排到帧末（deferred 队列在本帧所有 `_process` 跑完之后才 flush），所以 `Sys` 那边不用再收尾。
- **位移的时间基准是"帧"**（一帧 = `Sys._process` 的范围）：
  `_input` 累计 → `InputSys._process`（按键类消费）→ `TimeSys._process`（Tick 类消费，**拖拽走这里**）→ **帧末**（deferred flush）`_clear_mouse_delta()` 清零。
  一帧内多个 MouseMotion 事件累加，拖拽类指令按帧消费一次，因此指针停下时位移为 (0,0)（不漂），快移时拿到本帧总位移（不丢距离）。
  **清零只能在帧末**：若放在 `InputSys._process` 里，晚于它才被 Tick 触发的拖拽就永远读到 (0,0)。
- `static _send_key_status(key, isDown)`：按下→(首按则)入集合 + `Msg.send_key_press`；抬起→出集合 + `Msg.send_key_release`。
- 鼠标移动：这里只累计 `mouse_delta` / `mouse_position`，**不发事件**——`Pointer Move` 由 `PointerDetect._process` 判（本帧位移不为 0 就派发给 hover 的 UI，与 Pointer Enter / Pointer Exit 一样不经状态层）。
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
- **按需计算**：`static _process(delta)` 按 `InputSys.mouse_position` 刷新 `hover_ui/hover_char/map_position`；hover 变化时对新旧 UI 派发 `QName.pointer_enter / QName.pointer_exit`（两个内置事件名，放在 Config/QuickName.gd）。**一帧只跑这一次**：由 `InputSys._process` 在派发按键之前调，尾巴上再顺手收尾一次失焦关闭（`PointerDetect._blur_pending`，见 UI.md）。
- 执行函数只有一个：`static key(status_name)`（指令串 `PointerDetect.key "状态名"`）：
  - **不区分 press/hold/release/move，也不涉及键位**——"哪个状态满足了"由状态层判定，这里只把状态名当事件名派发。
  - **派发目标**：当前 hover 的 UI —— 指针不锁定（按住后指针会离开元素，所以"按住期间的事"不走这里）。
  - 命中刷新由 `InputSys._process` 里的 `PointerDetect._process` 负责（一帧一次、早于派发）；**派发里不再刷新命中**。
  - 命中 UI 时调 `ui.on_event(状态名)`，UI 侧按状态名等值匹配 `config["events"]` 里的指令。
  - **"按住期间每帧要做的事"不走这里**：走 `AutoSys`（`Script/Auto/Auto.md`：挂在状态上、每帧执行指令、状态不满足自动删）——指针层不参与，也就不需要捕获机制。
- 命中判定：UI 按**控件树倒序**（同级后画的在上，沿控件树先问孩子）取最上层、`control.get_global_rect()` 矩形命中；角色按身体 `CollisionShape2D` 矩形；地图按世界坐标 / `TileSpritePreset.tileset.tile_size` 换算（y 取反）。
- 驱动链路：`StatusPreset_Pointer` 定义按键状态（Pointer Press/Hold/Release、Submit）→ `SystemShortcutPreset_Pointer` 声明"状态满足→`PointerDetect.key` 指令"→ 满足时 `Msg.send_cmd`。输入全部来自 `InputSys` 的 `Msg` 消息，不用引擎 `gui_input`。
