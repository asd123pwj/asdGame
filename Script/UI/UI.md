# UI · UI 界面系统

## 定位
UI 系统遵循项目统一范式（见 `设计文档.md` §二/§三/§十）：**UIPreset**（配置）→ **UiSystem**（管理脚本）→ **UIBase**（元素基类）→ `Config/UI/` 配置类。
- `UIBase extends BaseClass`，**不直接继承 Control**：内部用变量持有 `control: Control`（真正的引擎节点），对外交互一律走 **`Msg`** 消息，不用自定义 signal。
- UI 描述放进 `ConfigBase.values`，玩家改配置 json 即可自定义。

## 目录与命名约定
```
Script/UI/
├─ UI.md                 # 本文档
├─ UIPreset.gd           # UI 预设（extends PresetRegister）：一条 UI 配置 + 实例化对应 UIBase
├─ UiSystem.gd           # UI 管理脚本（extends BaseClass）：挂载/移除/持有全部 UI
├─ UIBase.gd             # 元素基类（extends BaseClass，持有 control: Control）
└─ UI/                   # 具体元素放置目录
   └─ UI_Panel.gd        # 示例元素（class_name UI_Panel，配置里 ui_name = "UI_Panel"）
```
- 元素类 `class_name UI_XXX extends UIBase`，统一放 `Script/UI/UI/`。
- 配置类 `class_name UIPreset_XXX extends ConfigBase`，放 `Config/UI/`，`values: Array[Array]`（每条 = `UIPreset._init` 的位置参数）。

## 文件
| 文件 | 作用 |
|---|---|
| `UIPreset.gd` | UI 预设：一条 UI 配置（名字/实现类名/显示与交互配置），按类名实例化对应 `UIBase`，注册进 `static _we`。 |
| `UiSystem.gd` | 管理脚本：持 UI 根（CanvasLayer），按预设挂载/移除 UI，持有当前全部 UI 集合，操作时发 `Msg`。 |
| `UIBase.gd` | 元素基类：`extends BaseClass`，持有 `control: Control`；`build()` 生成控件树；指针交互由 `PointDetect` 回调，结果走 `Msg`。 |
| `UI/UI_*.gd` | 具体元素实现（如可拖动面板）。 |

## UIPreset.gd（extends PresetRegister）
```gdscript
var name: String          # UI 唯一名
var ui_name: String       # 实现类名，如 "UI_Panel"
var config: Dictionary    # 显示/交互配置
var ui: UIBase            # 按 ui_name 实例化的元素

static var _we: Dictionary[String, UIPreset] = {}
func _init(name, ui_name, config := {}): _we[name] = self; ...
static func get_(name) -> UIPreset: return _we[name]
```
- `_init` 里按 `ui_name` 用 `ProjectSettings.get_global_class_list()` 找类并 `new`，缓存到 `ui`（参考 `InventoryPreset`）。

## UiSystem.gd（extends BaseClass，管理脚本）
- 持 `var root: CanvasLayer`（UI 根，挂到主场景）与 `var uis: Dictionary[String, UIBase]`。
- `add_ui(name) -> Enums.Code`：查 `UIPreset.get_(name)` → `ui.build()` → 把 `ui.control` 挂到 `root` → 存入 `uis` → `Msg.send_ui_create(...)`。
- `remove_ui(name) -> Enums.Code`：摘除并 `Msg.send_ui_remove(...)`。
- `get_ui(name)` / `check_ui(name)`。

## UIBase.gd（extends BaseClass）
- 持 `var control: Control`（引擎对象）；`func build() -> Control` 生成控件树，返回 control。
- 显示内容：`control` 下可挂文本(Label)/按钮(Button)/滚动条(ScrollContainer) 等原生控件。
- 交互开关（可按需开启、可复用一个 UI）：`draggable / closeable / scalable / submittable / track_id`。
- 指针交互由 **`PointDetect`** 用 `InputSys` 检测命中后回调：`on_pointer_down()` / `on_pointer_move()` / `on_pointer_up()` / `on_submit()`；**不用引擎 `Control.gui_input`**。
- 交互事件统一走 **`Msg`**（不自定义 signal），且**按行为分函数**（函数名即行为，避免外部字符串写错）：
  - `Msg.send_ui_press/drag/release/submit/close/scale(ui)`、`Msg.send_ui_fade(ui, target)`；对应 `listen_ui_press/...`。
  - 仅控件自身的引擎内建信号（`Button.pressed`）保留，用于把按钮点击接回 UIBase 方法。
- 子类覆写虚接口实现具体外观（如 `UI_Panel`）。

## PointDetect（Script/Input/PointDetect.gd，extends BaseClass）
- 职责：监控指针目标 + 按需派发到目标（详见 `Input.md`）。
- **按需** `update_targets()` 刷新：`hover_ui`(指针下 UI) / `hover_char`(指针下角色) / `map_position`(指针地图格，逻辑坐标 y 向上)，不再每帧。
- **只提供执行函数，不监听按键**：`pointer_down/move/up`、`submit` 由状态→SystemShortcut→指令驱动（`StatusPreset_Pointer` + `SystemShortcutPreset_Pointer`），不再 `Msg.listen_key_*`，也不被 `Sys._process` 驱动。
- 命中 UI 判定按 `uis` 加入顺序取最上层，用 `control.get_global_rect()` 做矩形命中。

## 消息（MessageHub.gd 末尾补充）
- `send_ui_create(ui)` / `listen_ui_create(cb)`、`send_ui_remove(ui)` / `listen_ui_remove(cb)`。
- `send_ui_press/drag/release/submit/close/scale(ui)`、`send_ui_fade(ui, target)` 与对应 `listen_ui_*`：每个函数固定自己的 action（`PRESS/DRAG/RELEASE/SUBMIT/CLOSE/SCALE/FADE`），id 为 `format_ID(["UI", str(ui.ID), action])`，参考角色级消息。

## Config/UI/UIPreset_Basic.gd（extends ConfigBase）
```gdscript
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", { "size": [320, 220], "draggable": true }],
]
```
- 每条 = `UIPreset._init(name, ui_name, config)` 的位置参数。

## 已确认但暂缓 / 留空
- `PointDetect` 已提供 `hover_char` / `map_position`，但角色/地图的交互派发暂缓（等后续扩展）；`track_id`（UI 跟随角色）的"地图坐标→屏幕"投影依赖相机方案，接口先留。
- 多套 UI 版本（横竖屏/字体缩放）、可视化编辑器。
- 更细的 style 默认值回退链（元素→父→UI 根→全局默认）后续按需补。
