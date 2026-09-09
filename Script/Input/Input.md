# Input · 输入系统

## 定位
把引擎原始输入(键/鼠标)翻译成"按键状态"事件发到消息总线；支持"组合键"序列识别成整体按键。

## 文件
| 文件 | 作用 |
|---|---|
| `InputSystem.gd` | `InputSys`：接收引擎输入 → 记录按键状态 → 发消息。 |
| `InputCombo.gd` | `InputCombo`：把一串按键序列识别为一个组合键事件。 |

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
