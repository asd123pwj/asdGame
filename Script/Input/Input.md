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
- `edit_ui`：**正在编辑输入的 UI**。登记 / 清空由 `InputSys.begin_edit(ui)` / `InputSys.end_edit()` 这一对管
  （UI 侧的抢焦点、全选由 `UIInteract_Edit` 接着做）——**"正在编辑"那条状态消息也在这一对里发**
  （`QName.editing`，保持型外部检测）：少发就等于配置里"编辑中要屏蔽谁""回车算不算提交"全失效，
  所以两半绑在一处，别在别处自己赋 `edit_ui`。⇒ `_input` 里按键分三路：
  - **归输入框、不进状态层**（`_is_input_only_key`）：会打字的键（`unicode > 0`）+ 输入框自己的操作键
    （方向键 / 退格 / 删除 / Tab）。**方向键要拦**：输入框用的是**内置**方向键移动光标，
    放过去就会顺手触发 `QName.left/right/up/down` 那些方向状态（走路 / 开菜单）。
    **Home / End / PageUp·PageDown 不在表里**（那是"跳行首 / 翻屏"这类浏览用键，小短框用不上）⇒
    它们照常进状态层，将来想拿它们绑别的状态也不会被输入框抢走；
  - **回车**：照常进状态层，并**问 `QName.submit`**（`_submit_now`，先补一次 HOLD 把状态结算到**当下**）——
    满足 ⇒ `set_input_as_handled()` **吃掉这个事件**（多行框才不会顺手插一个换行）；不满足（按着 Shift）⇒
    **不吃** ⇒ 多行框自己把它插成一个换行 ⇒ 于是"回车提交、Shift+回车换行"成立。
    **本层只决定"这个事件吃不吃了"，不派发提交**（派发见下一条）；
  - **其余键照常进状态层**（修饰键 / 功能键…）："编辑中要不要响应"由配置的状态说了算。
  "正在编辑"这条状态是 **`QName.editing`**：由 `UIInteract_Edit.begin_edit / end_edit` 用**保持型外部检测**
  （`Msg.send_status_detected_manual / ..._undetected_manual`）手动开 / 关，状态侧配 `with_detect_manual: true`。
- **回车提交这条链**（"`Input Submit` 到底是谁送给输入框的"）：回车 → 状态层 `QName.submit`
  （= 回车 ∧ 没按 Shift，见 `Archetype_System`）→ `SystemManager.when_submit` 把 `QName.input_submit`
  派给 `InputSys.edit_ui`（正在编辑的那个输入框）→ 元素配置里那条 `[QName.input_submit, …]` 干实事
  （送到哪 + 清空 + 退编辑 + 刷，见 `UIPreset_Test`）。**输入层不参与这条链**，只负责如实转发按键。
  注意同一条状态上的快捷 `PointerDetect.key("Submit", false)` 要**不收编辑**（那个参数就是为它加的）：
  快捷可能先于监听跑，它一收编辑，这次派发就没了目标（实测踩过）。
  这次回车的**事件本身**由输入层吃掉（见上一条），所以多行框里不会留下换行。
- `static _input(event)`：被 `Sys._input` 调；区分 Key/MouseButton/MouseMotion，按键按下/抬起调 `_send_key_status`（`edit_ui` 非空时按上面两路走）。
- `static begin_edit(ui)` / `static end_edit()`：置 / 清 `edit_ui` **并**发"正在编辑 / 没在编辑"那条状态消息。
  `end_edit` 由 `UIInteract.end_edit` 命令、以及 `PointerDetect.key` 默认那句"点别处"调（键盘状态传
  `end_edit=false` 时不走那句）——**所有收编辑的路径都走它**：以前只有命令那条发了状态消息，
  "点别处"收掉编辑时状态层还停在"编辑中"（实测踩过）。
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
- 执行函数只有一个：`static key(status_name, end_edit := true)`（指令串 `PointerDetect.key "状态名"`；
  第二个参数 = 派发前要不要先"点别处退出编辑"，**键盘状态要传 false**，如提交那条）：
  - **不区分 press/hold/release/move，也不涉及键位**——"哪个状态满足了"由状态层判定，这里只把状态名当事件名派发。
  - **派发目标**：当前 hover 的 UI —— 指针不锁定（按住后指针会离开元素，所以"按住期间的事"不走这里）。
  - 命中刷新由 `InputSys._process` 里的 `PointerDetect._process` 负责（一帧一次、早于派发）；**派发里不再刷新命中**。
  - 命中 UI 时调 `ui.on_event(状态名)`，UI 侧按状态名等值匹配 `config["events"]` 里的指令。
  - **"按住期间每帧要做的事"不走这里**：走 `AutoSys`（`Script/Auto/Auto.md`：挂在状态上、每帧执行指令、状态不满足自动删）——指针层不参与，也就不需要捕获机制。
- 命中判定：UI 按**控件树倒序**（同级后画的在上，沿控件树先问孩子）取最上层、`control.get_global_rect()` 矩形命中；角色按身体 `CollisionShape2D` 矩形；地图按世界坐标 / `TileSpritePreset.tileset.tile_size` 换算（y 取反）。
- 驱动链路：`StatusPreset_Pointer` 定义按键状态（Pointer Press/Hold/Release、Submit）→ `SystemShortcutPreset_Pointer` 声明"状态满足→`PointerDetect.key` 指令"→ 满足时 `Msg.send_cmd`。输入全部来自 `InputSys` 的 `Msg` 消息，不用引擎 `gui_input`。
