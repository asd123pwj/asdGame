# UI · UI 界面系统

## 定位
UI 系统遵循项目统一范式（见 `设计文档.md` §二/§三/§十）：**UIPreset**（配置）→ **UiSystem**（管理脚本）→ **UIBase**（元素基类）→ `Config/UI/` 配置类。
- `UIBase extends BaseClass`，**不直接继承 Control**：内部用变量持有 `control: Control`（真正的引擎节点），不用自定义 signal。
- **一个 UI = 多个基本元素的组装**：根元素（如 `UI_Panel`）由 config["children"] 声明子元素（都是 UIBase 子类），build 时递归组装。
- **交互 = 指令**：元素不再用 `draggable/closeable/...` 开关，而是"事件→指令"——`config["events"]` 是 `[事件键, 指令串]` 的列表，事件发生即发送对应指令；**事件键统一用常量表示**（按键事件 = `[键值, Enums.KeyStatus.状态]`，指针事件 = 行为名 move/enter/exit），不拼字符串键名；指令里 `$parent`(挂载对象)/`$self`(自身) 在发送前替换为实例（`$@ID` 形式）。想要什么行为就配什么指令（拖动手柄配 drag 指令、关闭按钮配 close 指令）。
- **显示内容统一挂 `content` 属性**：元素展示什么由 content 决定，改内容 = `set_content(v)`（内部自动 `refresh()`），不必重建控件。

## 目录与命名约定
```
Script/UI/
├─ UI.md                 # 本文档
├─ UIPreset.gd           # UI 预设（extends PresetRegister）：一条 UI 配置 + create_element 工厂
├─ UiSystem.gd           # UI 管理脚本（extends BaseClass）：挂载/移除 UI 树（只管生命周期）
├─ UIInteract.gd         # UI 交互指令宿主（extends BaseClass）：close/open/drag_*/fade_to/set_content
├─ UIBase.gd             # 元素基类（extends BaseClass，持有 control: Control）
└─ UI/                   # 原子元素（每个都是 UIBase 子类，配置里 ui_name = 类名）
   ├─ UI_Panel.gd        # 面板容器：竖排布局，组装子元素
   ├─ UI_Label.gd        # 文本：content 即文本（配左键 PRESS 指令即"按钮"，配左键 HOLD 即"拖动手柄"）
   ├─ UI_Image.gd        # 图片：content = 纹理路径，set_content(新路径) 即改图
   └─ UI_Scroll.gd       # 滚动容器：content 为多行文本
```
- 元素类 `class_name UI_XXX extends UIBase`，统一放 `Script/UI/UI/`。
- 配置类 `class_name UIPreset_XXX extends ConfigBase`，放 `Config/UI/`，`values: Array[Array]`（每条 = `UIPreset._init` 的位置参数）。
- **原子元素尽量少**：显示/交互有明显差异才做子类（文本/图片/滚动/容器）；"按钮"= 文本元素 + press 指令，组合控件直接用 `children` 配置堆叠，不写子类。

## 文件
| 文件 | 作用 |
|---|---|
| `UIPreset.gd` | UI 预设：一条 UI 配置；`create_element(ui_name, name, config)` 为根 UI 与子元素共用的实例化工厂。 |
| `UiSystem.gd` | 管理脚本：挂载/移除**整棵 UI 树**（子元素一并登记/注销），只管生命周期。 |
| `UIInteract.gd` | **交互指令宿主**（静态方法自动注册为指令）：`UIInteract.close/open/drag/fade_to/set_content`。 |
| `UIBase.gd` | 元素基类：`build()` 生成控件并组装子元素；持 `content`/`target`/`children`；指针事件→指令。 |
| `UI/UI_*.gd` | 原子元素实现（容器/文本/图片/滚动）。 |

## UIPreset.gd（extends PresetRegister）
```gdscript
var name: String          # UI 唯一名
var ui_name: String       # 实现类名，如 "UI_Panel"
var config: Dictionary    # 显示/交互配置（含 children）
var ui: UIBase

static var _we: Dictionary[String, UIPreset] = {}
static func get_(name) -> UIPreset
static func create_element(element_name, ui_name, config := {}) -> UIBase  # 类名查找 + new，根/子元素共用
```

## UiSystem.gd（extends BaseClass）
- 持 `var root: CanvasLayer` 与 `var uis: Dictionary[String, UIBase]`。
- `add_ui(name)`：`build()`（含子元素）→ 挂到 root → **登记整棵树**：根用原名，子元素用 `"根名/子名"`（如 `MiniHUD/Close`）→ `Msg.send_ui_create`。
  - 子元素进 `uis` 是为了 **PointerDetect 能把指针命中派发到具体子元素**（如关闭按钮、拖动手柄）；`uis.values()` 后加入者靠前，倒序命中即"子元素优先于父"。
- `remove_ui(name)`：收集整棵树的登记名逐一注销 → `queue_free` 根控件（子元素随之释放）→ `Msg.send_ui_remove`。
- `get_ui(name)` / `check_ui(name)`：子元素用全名（`MiniHUD/Close`）。
- **只管生命周期，交互实现都在 `UIInteract`**。

## UIBase.gd（extends BaseClass）
- `var control: Control`；`build()` = `_create_control()` → `_apply_config()` → `refresh()` → `_build_children()`。
- **`var content: Variant`**：显示内容（子类解释：Label=文本、Scroll=多行文本、Image=纹理路径）。`set_content(v)` 改内容并自动 `refresh()`；子类覆写 `refresh()` 把 content 刷到控件。
- **`var parent: UIBase`**（挂载对象）：组装子元素时由父元素注入，是 `$parent` 的指向。
- **`var children: Array[UIBase]`**：按 `config["children"]`（每项 `[child_name, ui_class, child_config]`）组装，挂到 `_content_box()`（容器类覆写返回内部布局节点）。
- **事件→指令**：唯一入口 `on_event(事件名)`（由 PointerDetect 派发）：
  - 事件名就是**状态名**（如 `"Pointer Press Left"`、`"Right"`）——**UI 不感知按键**，键位只在状态层 `statuses` 的 `keys` 里配置；hover 变化不对应状态，用 `PointerDetect.EVENT_POINTER_ENTER / EVENT_POINTER_EXIT`。
  - 在 `config["events"]`（`[事件名, 指令串]` 列表）里**按等值**取指令串 → `Msg.send_cmd(UIInteract.resolve_cmd(指令串, self))`（解析 `$parent`/`$self` 占位符）。
  - 用列表而非字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），加新事件只需加一项。
  - 未配置的事件不发送（无默认回退），元素没有隐式行为。
- **只存"何时发什么指令"**：无 `close()/fade_to()` 等交互实现（都在 `UIInteract`），无 `draggable/closeable/...` 开关。

## 交互指令（Script/UI/UIInteract.gd，静态方法 → 指令）
- **这些都是纯副作用指令（`-> void`）**：只做 close/hide、改 position、起 Tween、转发消息，不返回值。因此被指令系统调用时不会在 `send_cmd` 的结果数组里多套一层，无需 `[0]` 剥离。
- **参数类型 `target: UIBase`**：指令里的 `$parent/$self` 由 `resolve_cmd` 转成 `$@ID`，指令系统执行 `$` 表达式时用 `instance_from_id` 取出**实例**再传入，所以这里收到的必然是 UIBase，不是 ID 也不是名字。
- **`_as_ui(target, cmd_name)`**：只做校验、不再做"名字→实例"归一化（该路径已由指令系统承担）。target 为空、或目标尚未 `build()`（`control == null`）时 **`push_warning` 指明是哪个指令**，而不是静默 return——避免配置/组装写错却无提示。
- **`resolve_cmd(cmd, sender)`**：解析占位符——`$self`→自身；`$parent`→父 UI，`$parent.parent`→祖父（链式任意级，`_climb_parent` 实现；**级别不足时 `push_warning` 并用可达的最高级替代**）；链尾 `.xxx` 原样保留（`$parent.parent.text` → `$@ID.parent…` 后由指令系统继续按表达式取属性）。
| 指令 | 作用 | 典型配置 |
|---|---|---|
| `UIInteract.close $parent` | 关闭（隐藏）目标 UI（发 `Msg.send_ui_close` + hide） | 关闭"按钮"的 press |
| `UIInteract.open $parent` | 重新显示（与 close 成对） | 外部再次唤出 |
| `UIInteract.drag $parent` | 把指针**本帧累计位移**（`InputSys.mouse_delta`）作用到目标 UI | 拖动手柄的逐帧状态（如 `"Mouse Left | Tick"`） |
| `UIInteract.fade_to $parent 0.0 0.5` | 透明度渐隐/渐显（alpha, duration；**指令调用须写全参数**） | 提示淡出 |
| `UIInteract.set_content $parent "文本"` | 修改显示内容（→ refresh） | 更新滚动区文本 |

## 原子元素（Script/UI/UI/）
| 类 | 职责 | 事件配置示例 |
|---|---|---|
| `UI_Panel` | 面板容器：PanelContainer+Margin+VBox，子元素竖排；自身无功能逻辑 | — |
| `UI_Label` | 文本：content 即文本；**配 `"Pointer Press Left"` 即"按钮"、配 `"Pointer Hold Left"` 即"拖动手柄"**（无需单独 Button 类） | `["Pointer Press Left", "UIInteract.close $parent"]` |
| `UI_Image` | 图片：content = 纹理路径，refresh 时 load；`set_content(新路径)` 即改图 | — |
| `UI_Scroll` | 滚动容器：content 为多行文本，内层 Label autowrap；`set_content` 即改展示。**ScrollContainer 默认最小尺寸为 0，必须用 `size` 配置可视区大小，否则不可见** | — |
- 组合控件（如带背景的按钮）直接用 `children` 配置堆叠（Panel 背景子元素 + Label 文字子元素），不写子类。
- 元素**不连接任何引擎信号**（含 `Button.pressed`）：点击/拖动等全部由 PointerDetect 命中 → 事件 → `on_event` → 指令/消息 派发，输入链路唯一。

## PointerDetect（Script/Input/PointerDetect.gd）
- 与之前一致：按需 `update_targets()`，`key_press/hold/release` 由状态→SystemShortcut→指令驱动。
- 命中判定改为 `control.is_visible_in_tree()`：父 UI 关闭(hide)后子元素不再可命中；`uis` 倒序遍历，子元素优先命中。

## Config/UI/UIPreset_Basic.gd（extends ConfigBase）
```gdscript
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", {
        "position": [30, 30], "size": [320, 220],
        "children": [
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "events": [["Pointer Hold Left", "UIInteract.drag $parent"]],
            }],
            # "按钮" = 文本元素 + "Pointer Press Left" 指令，无需 Button 子类
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [["Pointer Press Left", "UIInteract.close $parent"]],
            }],
            ["Info", "UI_Scroll", { "content": "初始内容" }],
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
]
```
- 组装读法：根 `UI_Panel` 含三个子元素——标题栏按住拖动父 UI、文本"按钮"关闭父 UI、滚动区展示内容；改展示内容只需 `get_ui("MiniHUD/Info").set_content(...)` 或发 `UIInteract.set_content` 指令。

## 消息（MessageHub.gd）
- `send_ui_create/remove(ui)` 与 `listen_ui_create/remove`。
- `send_ui_press/drag/release/submit/close/scale(ui)`、`send_ui_fade(ui, target)` 与对应 `listen_ui_*`：每个函数固定 action，id 为 `format_ID(["UI", str(ui.ID), action])`。
- 现在这些消息主要作为**未配指令元素**的默认出口；配了指令的元素改走 `Msg.send_cmd`。

## 已确认但暂缓 / 留空
- `PointerDetect` 已提供 `hover_char` / `map_position`，角色/地图的交互派发暂缓；`track_id`（UI 跟随角色）随开关一起移除，待需要时以指令形式回归（如 `UIInteract.follow $parent $@角色ID`）。
- 多套 UI 版本（横竖屏/字体缩放）、可视化编辑器、缩放指令（`UIInteract.scale`）。
- 更细的 style 默认值回退链（元素→父→UI 根→全局默认）后续按需补。
