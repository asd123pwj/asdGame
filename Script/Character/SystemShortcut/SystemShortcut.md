# SystemShortcut · 系统快捷

## 定位
"系统快捷系统"：比 `Interaction` 更简单的联动——**依赖某状态满足后，直接执行指令系统（`CmdSys`）的一条指令**。
不做属性/背包操作，只把配置里的指令串丢给 `Msg.send_cmd`。是 Interactions 的轻量版。

## 文件（一层）
| 文件 | 作用 |
|---|---|
| `SystemShortcutPreset.gd` | 一条快捷预设(依赖状态 + 指令串)。`extends PresetRegister`。 |
| `SystemShortcuts.gd` | 每个角色的快捷集合。`extends BaseClass`。 |

## SystemShortcutPreset.gd 说明（Preset）
- 一条快捷 = `name / dependence_status(依赖状态) / config(指令串)`。
  - `dependence_status` 支持 `状态名@unique_name` 定向语法（见 `Msg._resolve_target`）。
  - `config` 是交给 `Msg.send_cmd` 的指令串，可含多条（`\v` 分隔，语义同 `CmdSys`）。
- `listen(char_)`：`Msg.listen_status_satisfied(char_, dependence_status, ...)` → 满足时 `Msg.send_cmd(config)` + `Msg.send_shortcut_act`。
- `unlisten(char_)`：取消监听。（`send_shortcut_add/remove` 由集合 `SystemShortcuts` 发出，与 `InteractionPreset`/`Interactions` 分工一致。）
- 触发时机与 `InteractionPreset` 一致：**只监听 satisfied**（"条件不满足"由状态自身的配置表达，如 `Unsatisfied` 监听器，不需要在此显式写）。

## SystemShortcuts.gd 说明（集合）
- `_init(me, names[])` → `add_shortcut`。
- `add_shortcut`：装预设 + `listen` + `Msg.send_shortcut_add`；`remove_shortcut`：`unlisten` + `Msg.send_shortcut_remove`；`check_exist(name)`。

## 与 Interaction 的区别
| | Interaction | SystemShortcut |
|---|---|---|
| 执行体 | `Interaction_xxx` 实现类 | 直接一条指令串 |
| 目标/参数 | 从 status 取 target、做属性运算 | 无，指令自己处理 |
| 适用 | 需要角色间属性/背包交互 | 状态→触发系统级指令（如 UI 指针派发） |

## 典型用法：指针派发（PointDetect）
`PointDetect` 只保留执行函数（`pointer_down/move/up`、`submit`），**不再自己监听按键**。
按键 → `StatusPreset_Pointer` 定义的状态（Pointer Down/Hold/Up、Submit）→ `SystemShortcutPreset_Pointer` 声明"状态满足→执行 `PointDetect.xxx` 指令"。
链路：`Msg.listen_key_*`(在 StatusPreset 内) → `send_status_satisfied` → `SystemShortcut` → `Msg.send_cmd("PointDetect.pointer_down")`。
