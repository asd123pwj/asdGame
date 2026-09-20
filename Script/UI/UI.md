# UI · UI 界面系统

## 定位
UI 系统遵循项目统一范式（见 `设计文档.md` §二/§三/§十）：**UIPreset**（配置）→ **UiSys**（管理脚本，文件 `UiSystem.gd`）→ **UIBase**（元素基类）→ `Config/UI/` 配置类。
- `UIBase extends BaseClass`，**不直接继承 Control**：内部用变量持有 `control: Control`（真正的引擎节点），不用自定义 signal。
- **一个 UI = 多个基本元素的组装**：根元素（如 `UI_Panel`）由 config["children"] 声明子元素（都是 UIBase 子类），build 时递归组装。
- **交互 = 指令**：元素不再用 `draggable/closeable/...` 开关，而是"事件→指令"——`config["events"]` 是 `[事件名, 指令串]` 的列表，事件发生即发送对应指令；**事件名就是状态名**（统一来自 `QName`，如 `QName.mouseLeft`；UI 不感知键位，键位只在状态层配），hover 变化用 `QName.pointer_enter` / `QName.pointer_exit`；指令里 `$self.parent`(挂载对象)/`$self`(自身) 在发送前替换为实例（`$@ID` 形式）。想要什么行为就配什么指令（拖动手柄配 drag 指令、关闭按钮配 close 指令）。**配置里指令串外层一律用单引号**（Godot 与 Python 一样两种引号都行）：里面要写双引号（路径/字符串参数）时就不必转义成 `\"`，写出来就是指令本身的样子。
- **显示内容统一是 `config["content"]`**（**没有同名成员变量**）：元素展示什么由它决定，改内容 = 写 `config["content"]`（`Utils.write "$self.config.content" 值`）再在**下一条**接 `$self.refresh("content")`（只改了它这一项），不必重建控件。**路径参数用双引号包住**：顶层引号 = 字面字符串，里面的 `$` 不再被当成取值式，路径原样传进函数（不必手写 `\$` 转义）。

## 目录与命名约定
```
Script/UI/
├─ UI.md                 # 本文档
├─ UIPreset.gd           # UI 预设（extends PresetRegister）：一条 UI 配置 + create_element 工厂
├─ UiSystem.gd           # UI 系统（class_name UiSys，extends BaseClass）：登记表 + 登记名规则 + 取件（成员全静态）
├─ Interact/             # 交互指令宿主：UIInteractBase 是基类（指令前缀 + 共用校验），一个交互一个文件
│  ├─ UIInteractBase.gd         # 基类：CMD_HOST（指令前缀，声明一次）+ _as_ui（组内共用校验）
│  ├─ UIInteract_OpenClose.gd   # open / close（含 _build_open / _place / _child_ui 与失焦关闭）
│  ├─ UIInteract_Drag.gd        # drag + 每帧 dragging
│  ├─ UIInteract_Rescale.gd     # rescale + 每帧 rescaling
│  ├─ UIInteract_Fade.gd        # fade_to
│  ├─ UIInteract_Edit.gd        # begin_edit / end_edit
│  ├─ UIInteract_SwapConfig.gd  # （已退役）对调两项现在用 Utils.swap
│  ├─ UIInteract_SwitchValue.gd # switch_value（列表里"有就删、没有就加"）
│  └─ UIInteract_SetTop.gd     # set_top（点击置顶：绘制 + 命中都提前）
├─ UIBase.gd             # 元素基类（extends BaseClass，持有 control: Control）
└─ UI/                   # 原子元素（每个都是 UIBase 子类，配置里 ui_name = 类名）
   ├─ UI_Panel.gd        # 面板容器：竖排布局，组装子元素
   ├─ UI_Label.gd        # 文本：content 即文本（配左键 PRESS 指令即"按钮"，配左键 HOLD 即"拖动手柄"）
   ├─ UI_Image.gd        # 图片：content = 纹理路径（改图 = 写 config["content"] + refresh("content")）
   └─ UI_Scroll.gd       # 滚动容器：content 为多行文本
```
- 元素类 `class_name UI_XXX extends UIBase`，统一放 `Script/UI/UI/`。
- 配置类 `class_name UIPreset_XXX extends ConfigBase`，放 `Config/UI/`，`values: Array[Array]`（每条 = `UIPreset._init` 的位置参数）。
- **原子元素尽量少**：显示/交互有明显差异才做子类（文本/图片/滚动/容器）；"按钮"= 文本元素 + press 指令，组合控件直接用 `children` 配置堆叠，不写子类。

## 文件
| 文件 | 作用 |
|---|---|
| `UIPreset.gd` | UI 预设：一条 UI 配置；`create_element(ui_name, name, config)` 为根 UI 与子元素共用的实例化工厂。 |
| `UiSystem.gd` | UI 系统 `UiSys`：开启/登记**整棵 UI 树**（子元素一并登记），成员全静态，日常直接 `UiSys.xxx`。 |
| `Interact/UIInteractBase.gd` | **交互组基类**：指令前缀（`const CMD_HOST := "UIInteract"`）+ 组内共用校验 `_as_ui`。交互按"一个交互一个文件"拆在 `Interact/` 下（`UIInteract_OpenClose.gd`、`UIInteract_Drag.gd`、`UIInteract_Rescale.gd`、`UIInteract_Fade.gd`、`UIInteract_Edit.gd`、`UIInteract_SwitchValue.gd`、`UIInteract_SetTop.gd`，都 `extends UIInteractBase`），所以**对外只有一套指令名** `UIInteract.open/close/drag/rescale/fade_to/begin_edit/end_edit/switch_value/set_top`。元素自己的普通方法不必包成交互——指令系统能直接调：整行写 `$self.refresh`（见下）。加一个交互 = 加一个 `UIInteract_Xxx.gd` + 静态方法，指令名自动是 `UIInteract.xxx`（机制见 `CmdSys` 的命令前缀组）。**开启（open + 摆位 + 子方法 + 失焦关闭）也在这个组里**（`UIInteract_OpenClose.gd`）。 |
| `../Auto/AutoSystem.gd` | `AutoSys`：**状态驱动执行器**（状态满足期间每帧执行一条指令，不满足自动删）。按住类交互（等比缩放）靠它，见 `Script/Auto/Auto.md`。 |
| `UIBase.gd` | 元素基类：`build()` 生成控件并组装子元素；持 `config`/`children`/`parent`；指针事件→指令。 |
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

## UiSystem.gd（class_name UiSys，extends BaseClass）
- **成员全是静态的**：`static var root: CanvasLayer` 与 `static var uis: Dictionary[String, UIBase]`，调用直接写 `UiSys.uis` / `UiSys.root` / `UiSys.get_ui(...)`，不用经 `Sys.uiSys`（那个实例只用于启动时跑一次 `_init` 建 UI 根）。**开启不在 UiSys**：见 `UIInteract_OpenClose.open`。
- **挂载规则**（决定 UI 树 ⇒ 决定"关谁连谁一起关"和 `$self.parent` 的级数）：有 `anchor`（触发它的那个元素）→ **挂在 anchor 下**；没有 anchor → 挂在 `host` 下；都没有 → 挂 UI 根（独立 UI）。所以"菜单开子菜单"得到的是一棵**单链子树**：`MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`。
- **画在谁上面**：UI 根是 `CanvasLayer`，层号取 `UiSys.ROOT_LAYER = 100`——**必须大于地图**（地图每个子层用自己的 `CanvasLayer.layer = 子层 id`，世界层 0 就是 0~5，以后加世界层还会更大），默认值 1 会被地图盖住。
- **点一下谁谁在最前**：`UIInteract_SetTop.set_top`（`PointerDetect.key` 里除"指针移动"外的派发自动调它，`open` 也调）。**提的是"窗口"不是被点到的小元素**——沿 `parent` 链爬到最外层那个 UI（挂 UI 根的那个）再排；直接对元素 `move_to_front()` 有两个后果：同级窗口没动（看着没生效）+ 元素在 VBox/PanelContainer 里重排兄弟 = 改布局（"子 UI 在面板里乱窜"）。爬完只需一句 `control.move_to_front()`：**命中已经和绘制同序**（见下），不用再维护登记表顺序。同一次按住里 HOLD 每帧派发，靠"最近提的是哪个窗口"去重。
- **登记名规则**（唯一的"寻址"约定，`_reg_name`，**只有这一条**）：没有挂载点 → 就是预设名（`MiniHUD`）；有挂载点 → `挂载点的登记名/名字`（`MiniHUD/Menu`、`MiniHUD/Menu/Edit/MenuEdit`）。**"开出来的 UI"与"配置里的子元素"共用它**（子 UI 的名字就是它的预设名），所以登记表是一整棵 `/` 连接的树；**"是否能复用"就是一次 `uis.get(登记名)`**，不需要按类型遍历。同一挂载点下不要重名。
- `open_ui(preset_name, host := null, anchor := null)`：**全项目唯一的开启入口**（普通 UI 与菜单同一条路，不要再写第二个）。
  - `host` 为空 → 独立 UI：建预设自己那份 → 挂 `root` → 登记（登记名就是预设名，如 `MiniHUD`）→ `Msg.send_ui_create`。
  - 给了 `anchor` / `host` → 深拷贝模板 → `挂载点.add_child_element` 挂到它下面 → **登记名 = `挂载点登记名/预设名`**（如 `MiniHUD/Menu`、`MiniHUD/Menu/Edit/MenuEdit`）；两者都不给则挂 UI 根、登记名就是预设名。
  - 已存在就**只显示 + 重新摆位**，不重建控件——"是否存在"就是一次字典查找 `uis.get(登记名)`（命名规则见 `UiSys` 文件头），**没有任何按 UI 类型的特判**。
  - 子元素进 `uis` 是为了 **PointerDetect 能把指针命中派发到具体子元素**（如关闭按钮、菜单项）；`uis.values()` 后加入者靠前，倒序命中即"子元素优先于父"。
- `get_ui(name)`：按登记名取（子元素用全名，如 `MiniHUD/Info`）。
- `register_child(parent, child)` / `find_name(ui)` / `_reg_name(mount, name)`：登记与反查，都用 `_reg_name` 那一条规则（`挂载点名/名字`）——所以开出来的 UI 与配置子元素同名规则，开/关的取件（`UIInteract_OpenClose._child_ui`，就是 `uis.get(_reg_name(...))`）才命得中。
- **"给某个 UI 加/减东西"= 开/关一个预设 UI**：不再有 `add_close_button` / `remove_close_button` 这类成对的专门函数（那正是"同一需求两套策略"）。关闭按钮就是一个普通预设 `CloseButton`（`Config/UI/UIPreset_Basic.gd`，`open_at = ANCHOR_TOP_RIGHT_IN` 开在锚点内部右上角），加它 = `open <宿主> CloseButton <宿主>`，减它 = `close <宿主> CloseButton`。
- **缩放手柄**同样是普通预设 `ResizeButton`（图标 `content` + `open_at = ANCHOR_BOTTOM_RIGHT_IN` 开在锚点内部右下角），**只有一条事件**，而且不直接调缩放函数，而是交给 `AutoSys`：
  ```gdscript
  "events": [["Mouse Left", "UIInteract.rescale $self.parent $event"]],
  ```
  读作：按住时调 `rescale` 登记（`$event` = 触发它的事件名 = 状态名）；之后每帧由 AutoSys 调 `rescaling <手柄挂着的那个 UI>`；松手（状态不满足）时 AutoSys 自己把这条登记删掉——**所以不用写"松开"**。两者都声明了 `free`（否则会被宿主的竖排布局排走）。
  - 用 `Hold` 而不是 `Press`：**状态层只在"满足状态变化"时广播**，所以 Hold 只在"开始按住"那一下触发一次——正好用来做"登记"；之后的每帧由 AutoSys 驱动，不需要带 `| Tick` 的状态。
  - 状态名不在配置里重复写：`$event` 由 `UIBase._resolve_cmd` 换成带引号的触发事件名（状态名统一来自 `QName`，见 `Config/QuickName.gd`）。
- **`AutoSys`（Script/Auto/Auto.md）——按住类交互为什么需要它**：等比缩放必然让手柄离开指针（缩小时手柄往里跑、放大时往外跑），而事件默认按 hover 派发 → 指针一离开，事件就断，表现就是"横向还行、纵向停住"。AutoSys 把"每帧做什么"挂在**状态**上（状态满足与指针在哪无关），状态一结束就自动删登记，所以：元素侧只写一条事件、不用捕获鼠标、不用手工退订、也不用存跨帧状态。
- **按住类指令一律成对**：`rescale`/`drag` 是**登记入口**（配置里写它们，内部用 `Callable.bind` 把活交给 AutoSys，不拼指令串），`rescaling`/`dragging` 是**每帧执行**（不写配置）。`rescale` 的算法是增量式的（`scale *= |指针-左上角| / |上帧指针-左上角|`），所以既不需要"记录抓手位置"（按下不跳变），也不需要注册/注销回调。
- **只管生命周期，交互实现都在 `UIInteract`**。

## UIBase.gd（extends BaseClass）
- `var control: Control`；`build()` = `_create_control()` → `_apply_config()` → `refresh()` → `_build_children()`。
- **`config["content"]`（只是一个配置键，没有成员变量）**：显示内容（子类解释：Label=文本、Scroll=多行文本、Image=纹理路径）。子类覆写 `refresh(key)`，在里面读 `config.get("content")` 刷到控件。**不做成属性 set 自动刷**：要拦的会是整张 config（还有 events/size/…），而 config 是 Dictionary、拦不住写入——换成带 `_set/_get` 的对象则读点全要改，不划算。所以统一"**写 config + 紧跟一条 `$self.refresh`**"。
- **`var parent: UIBase`**（挂载对象）：组装子元素时由父元素注入，是 `$self.parent` 的指向。
- **`var children: Array[UIBase]`**：按 `config["children"]`（每项 `[child_name, ui_class, child_config]`）组装，挂到 `_content_box()`（容器类覆写返回内部布局节点）。
- **事件→指令**：唯一入口 `on_event(事件名)`（由 PointerDetect 派发）：
  - 事件名就是**状态名**（统一来自 `QName`，见 `Config/QuickName.gd`）——**UI 不感知按键**，键位只在状态层 `statuses` 的 `keys` 里配置；hover 变化不对应状态，用 `QName.pointer_enter / QName.pointer_exit`。
  - 在 `config["events"]`（`[事件名, 指令串]` 列表）里**按等值**取指令串 → `Msg.send_cmd(_resolve_cmd(指令串, 事件名))`（`UIBase` 自己的私有助手，解析 `$self.parent`/`$self`/`$event` 占位符）。
  - 用列表而非字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），加新事件只需加一项。
  - 自己没配的事件**冒泡给父级**，冒泡到根都没有才什么都不做（元素没有隐式行为）；于是"整块面板的行为"在子元素上同样生效（如菜单面板启用拖拽后，按住菜单项也能拖），`$self/$self.parent` 以"配了指令的那个元素"为基准。
- **运行时增改**：`add_child_element(name, ui_class, config, reg_name := "")` 加子元素（内部交给 `UiSys.register_child` 登记，登记后才可被指针命中；`reg_name` 由开 UI 的路径显式指定，普通子元素留空）；对调两项配置用 `Utils.swap`（`Utils.gd`，两条路径写出来）、`switch_value(键, 值)` 在一个列表里"有就删、没有就加"（两者都是开关式按钮的底座：菜单的"启用关闭按钮"用前者、"启用拖拽"用后者——直接开关宿主 `events` 里的那一条绑定，不必预摆两套）。"关闭按钮"连新指令都不需要：它是普通预设 `CloseButton`，用 `open` / `close` 开关。
- **开关式按钮（可选框）**：不需要专门元素——同一个元素上放两套配置（`events` / `content` 与 `events_2` / `content_2`），点击时"做事 + `Utils.swap` 对调"，下次点击自然走另一套；**只加减一项**（如给宿主加/减一条绑定）用 `switch_value`，连第二套配置都不用写。事件串里多条命令用 `\v` 分隔（见 `CmdSys.execute`）。
- **config 可选属性**：`position` / `size` / `content` / `children` / `events` / `visible` / `free`（自由定位：挂到叠加层的非容器挂载点，`position`/`size` 不被父级布局覆盖，用于"右上角的关闭按钮""菜单""键盘的每个键"这类元素）。**配置子元素与运行时加的子元素共用这条规则**（`_build_children` 与 `add_child_element` 一致）：配了 `free` 就进叠加层任意摆，没配才进内容盒（容器类 = 竖排）。
  - `font_size`（字号）/ `font_color`（字色）与 `background`（背景图路径）是**公共属性**（都在 `UIBase._apply_config` 里读，不是某个元素独有）：
    - `font_size` / `font_color` 作用在**配它的那个控件**上——主题重写不向下传，所以要小字/深色字就配在真正显示文本的元素上。**不配字色就是主题默认（接近白色）**，配在浅色底图上会看不见。
    - `background`（九宫格底图）由 `UIBase._apply_background` 统一实现：找本元素控件的 stylebox 槽套上去（槽名由 `_background_slot` 按 `panel → normal → background` 取第一个存在的）。**实测各元素对应哪个槽**：

      | 元素 | 内部控件 | 可用的槽 |
      |---|---|---|
      | `UI_Panel` | PanelContainer | `panel`（它覆写 `_apply_background`，套在内层 `_panel` 上） |
      | `UI_Label` | Label | `normal` |
      | `UI_Scroll` | ScrollContainer | `panel` |
      | `UI_Image` | TextureRect | **无**（TextureRect 本身不画 StyleBox，配了只警告一次、不画） |

      控件一个槽都没有时警告一次、不画——要"带底"就换有槽的元素（文字带底 = `UI_Panel` 里放 `UI_Label`，键盘的键就是这么做的）。**整块底图走它，不要放 Image 元素当背景**——Image 属于内容，摆在叠加层上会盖住别的子元素。
    - 九宫格边距 = `background_slice`（**每张底图各自给**，跟着图的圆角走；不写 = 0 = 整张拉伸）。
  - `size` 里为 **0 的那一维按"内容最小尺寸"补足**（`_fit_size()`；"内容要多大"由可覆写的 `_content_size()` 给出）：`[150, 0]` = 宽固定、高随内容；`[0, 0]` = 完全由内容决定。**必须补**——控件尺寸为 0 时 `get_global_rect()` 是退化矩形，PointerDetect 永远命中不到它（菜单"一打开就没了"就是这么来的：矩形高度 0 → 失焦判定以为指针在菜单外 → 同一帧里就把它关了）。
  - **`UI_Panel` 的 `_content_size()` 必须问内部的 `PanelContainer`，不能问根控件**：根是普通 `Control`，**不会汇总子元素的最小尺寸**，问它只会得到 `custom_minimum_size`（`[150, 0]` → 高度就是 0）。而且建时还没进树、字体主题都问不出来，所以要挂在 `_panel.minimum_size_changed` 上再补一次。
  - 指令串参数：**只有中间带空格时才需要引号**（如 `"Mouse Left | Tick"`），其余直接写名字（如 `open_menu $self Menu`）。
  - **自由定位元素不要设 `Control.top_level`**：那会让它不再继承父级可见性（宿主 `hide()` 后它还留在屏幕上、也还能被命中）。摆放时把屏幕坐标换算成**宿主坐标系的 `position`**（挂载点原点即宿主原点）；也不要用 `set_global_position`——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏。
- **只存"何时发什么指令"**：无 `close()/fade_to()` 等交互实现（都在 `UIInteract`），无 `draggable/closeable/...` 开关。

## 交互指令（Script/UI/UIInteract.gd，静态方法 → 指令）
- **这些都是纯副作用指令（`-> void`）**：只做 close/hide、改 position、起 Tween、转发消息，不返回值。因此被指令系统调用时不会在 `send_cmd` 的结果数组里多套一层，无需 `[0]` 剥离。
- **参数类型 `target: UIBase`**：指令里的 `$self.parent/$self` 由 `UIBase._resolve_cmd` 转成 `$@ID`，指令系统执行 `$` 表达式时用 `instance_from_id` 取出**实例**再传入，所以这里收到的必然是 UIBase，不是 ID 也不是名字。
- **`_as_ui(target, cmd_name)`**：只做校验、不再做"名字→实例"归一化（该路径已由指令系统承担）。target 为空、或目标尚未 `build()`（`control == null`）时 **`push_warning` 指明是哪个指令**，而不是静默 return——避免配置/组装写错却无提示。
- **`UIBase._resolve_cmd(cmd, event_name)`**：解析占位符——**只认两个**：`$self`→自身（`$@ID`）、`$event`→触发事件名（**自带引号**，因为事件名里常有空格）；路径参数交给"双引号 = 字面字符串"那条规则。父级/内容一律在 `$self` 上接着写取值链，交给指令系统按表达式解析：`$self.parent`→父 UI、`$self.parent.parent`→祖父（级数任意）、`$self.config.content`→自身显示内容——**没有 `$parent` / `$text` 这类专用占位符**（能从 `$self` 取到的就不另立语法；取不到时表达式给 null，由目标指令自己警告）。它是 `on_event` 的私有助手，放在 `UIBase` 里（没有第二个使用者）。
**两种写法，能力不同，别混用**：
- `$…` 开头的整行 = **调用**（元素自己的**实例方法**只能这么调，如 `refresh`）：末尾写方法名 ⇒ **零参调用**（用签名里的默认值，`refresh()` 的 key 默认 `""` = 全刷）；要传参就写常规括号 `refresh("content")`——括号里只收**位置参数**（常量或 `$…` 取值），**挂不了 `--flag`**（会被当成普通字符串参数原样传进去）。
- `类.方法 参数…` = **命令**（只收**静态**方法 ⇒ 各交互与 `Utils.*` 都属这一类）：参数用空格分开，支持**位置参数**、**命名参数** `--名字 值`（可跳过有默认值的参数）、**flag** `--名字`（= true）。**加括号不行**（整串会被当成方法名 ⇒ `No command: UIInteract.begin_edit($@123)`）。
- 分工：交互写 `UIInteract.xxx …`（要 flag 就在这儿挂）；调元素自己的方法写 `$self.方法("参数")`。
| 指令 | 作用 | 典型配置 |
|---|---|---|
| `UIInteract.close $self.parent` | 关闭（隐藏）目标 UI（发 `Msg.send_ui_close` + hide） | 关闭"按钮"的 press |
| `UIInteract.open [宿主] 预设名 [锚点] [--close_on_blur] [--close_on_move]` | 开启/重开一个 UI（显示 + 按 `open_at` 摆位；不重建控件）。**锚点同时是挂载点**（子菜单挂到触发它的菜单项下）；宿主与锚点都省略 = 独立 UI。后两个 flag 是**关闭行为**（bool，**默认 false**）：`--close_on_move` = 指针挪开就收（hover 展开的子菜单）、`--close_on_blur` = 有按键派发时不在它上面就关（右键菜单）；**要哪种就在开的这一句写出来**——预设里不再声明它（"在哪开、为什么开"只有这一句知道） | 面板右键开菜单：`open $self Menu $self --close_on_blur` |
| `UIInteract.drag $self.parent $event` | **按住拖动**（登记入口）：把"每帧拖 `$self.parent`"挂到这个按住状态上，松手自动停 | MiniHUD 标题栏、整块键盘面板 |
| `UIInteract.rescale $self.parent $event` | **等比缩放**（登记入口）：每帧 `scale *= |指针 - 面板左上角| / |上帧指针 - 面板左上角|`（增量式，以左上角为中心，上下限取 `SysCfg.resize_min_scale / resize_max_scale`） | 缩放手柄 `ResizeButton` |
| `$event` | 占位符，由 `resolve_cmd` 换成**带引号的触发事件名**（= 状态名 = Key 名），所以配置不必再抄一遍状态名 | 上两条都在用 |

> 按住类交互在代码里成对写：`drag`/`rescale` 是**登记入口**（配置里写它们），
> `dragging`/`rescaling` 是**每帧执行**（不写配置，只由 `AutoSys` 调）。见 `Script/Auto/Auto.md`。
| `UIInteract.fade_to $self.parent 0.0 0.5` | 透明度渐隐/渐显（alpha, duration；**指令调用须写全参数**） | 提示淡出 |
| `Utils.write "<路径>" <值>` | **通用的"按路径写值"**（`Utils.gd`，只有两个参数：路径里已带宿主）：路径语法与取值式**完全一致**（`$self.config.content`、`@ID.config.content`、`Test.int1`、`a.b[0].c`、`$UiSys.get_ui(名字).config.content`——多层、列表下标、函数头都行），走的就是指令解析器（`CommandParser.write`）。**路径要用双引号包住**（顶层引号 = 字面字符串，`$` 开头不会被当取值式；手写 `\$` 转义也行）。**只写数据、不刷新界面** ⇒ 改完接一条 `$self.refresh("content")` | `MenuBind` 回车：`Utils.write "$self.parent.parent.parent.parent.config.bind" $self.control.text` |
| `Utils.swap "<路径A>" "<路径B>"` | 通用的"两项对调"（字典键 / 实例成员 / 类脚本静态都行），开关式按钮的底座；**界面刷新不在这里** ⇒ 改完接一条 `$self.refresh("content")` | 菜单 CloseToggle：`Utils.swap "$self.config.events" "$self.config.events_2"` |
| `Utils.copy <文本>` | 把文本复制到**系统剪贴板**（平台不支持会警告）。名字靠取值链取：`Utils.copy $self.parent.parent.config.reg_name` | 右键菜单"复制名称" |
| `$self.refresh("content")` | **调用**（`$` 开头的整行 = 做事，末尾是方法就调它；`()` 里可以带参数）：刷新界面不用包一条交互——指令系统本来就能调方法，`refresh(key)` 是 `UIBase` 上的普通方法（子类继承自然生效）。**改了什么就刷什么**：只改了 content 就传 `"content"`，一次改了好几项 / 不确定才不传 key（全刷）。目标算出来的也能调：`$UiSys.get_ui($self.parent.config.bind).refresh("content")` | `Utils.write "$self.config.content" 值\v$self.refresh("content")` |
| `UIInteract.begin_edit $self.parent` | 让目标开始编辑（`UI_Input`：抢焦点 + 置 `InputSys.edit_ui`）——"打开后直接就能打字"用它 | `open … \v begin_edit …` |
| `UIInteract.end_edit $self.parent` | 让目标结束编辑（清 `InputSys.edit_ui` + 放焦点）。**"提交后要不要退出编辑"由配置决定**：要退出就写它；搜索框那种"提交完继续打字"就别写 | `Utils.write … \v end_edit $self \v …refresh("content")` |
| ~~`UIInteract.swap_config`~~（已退役） | 对调两项改用 `Utils.swap`：两条路径直接写出来，后面接一条刷新（换的是自己那两项就 `$self`）——**开关式按钮就靠它 + 多命令实现** | `Utils.swap "$self.config.content" "$self.config.content_2"\v$self.refresh("content")` |
| `UIInteract.switch_value $self.parent 键 值` | 在 `config[键]` 列表里开关一个值：**已有（按内容比）就删、没有就追加**；`值` 可以是变量（如 `$QName.UI_event_mouseLeft_drag`）。`events` 这类列表在派发时才读，所以改完立刻生效 | 菜单"启用拖拽"：往宿主 `events` 里加/减一条拖动绑定 |
| `UIInteract.set_top $self.parent` | 把 target 所在的**窗口**（沿 `parent` 爬到最外层那个 UI）提到最前：只需一句 `control.move_to_front()`——命中已与绘制同序（见下），不用再维护登记顺序。**一般不用写**：`PointerDetect.key` 里"点它"就会自动调（`open` 也会调，新开的排最前） | 点一下谁谁在最上面 |
| `UIInteract.close [预设名]` | 关闭（隐藏）：**不写预设名 = 关 target 自己**；写了 = 关"挂在 target 下的那个预设 UI"（按"挂载点 + 预设名"查，没开过就什么都不做）。与 `open` 成对：给某个 UI 加/减东西 = 开/关一个预设 | 关闭"按钮"、开关式按钮的"移除"一侧：`close <宿主> CloseButton` |
| `UIInteract.toggle [目标] [预设名]` | **开关**：现在显示着就关、否则开（开/关都走本文件那两条，复用与摆位照旧）。键状态只在"满足变化"时给一次，写两条指令做不到判断该开还是该关，所以要有它 | `J → toggle --preset_name TestShow` |

## 原子元素（Script/UI/UI/）
| 类 | 职责 | 事件配置示例 |
|---|---|---|
| `UI_Panel` | 面板容器：PanelContainer+Margin+VBox，子元素竖排；自身无功能逻辑。`background` 可给整块面板铺一张九宫格底图 | — |
| `UI_Label` | 文本：content 即文本；**绑 `"Mouse Left"`（按住）即"按钮"/"拖动手柄"**（配 `UIInteract.drag $self.parent $event` 就是后者），要"按下那一下"就用 `"Mouse Left | Press"`（无需单独 Button 类） | `["Mouse Left", "UIInteract.close $self.parent"]` |
| `UI_Image` | 图片：content = 纹理路径，refresh 时 load；改图 = 写 `config["content"]` + 一条 `$self.refresh` | — |
| `UI_Scroll` | 滚动容器：content 为多行文本，内层 Label autowrap。**ScrollContainer 默认最小尺寸为 0，必须用 `size` 配置可视区大小，否则不可见**。结构与 `UI_Panel` 同一套：`root(Control) → Scroll(ScrollContainer) → Label` + `Overlay(Control)`，**free 子元素挂 Overlay**（不能挂在滚动容器里：会被裁、尺寸被压成 0） | — |
| `UI_Input` | 输入框（LineEdit）：content 是**配置里写的初值**（`refresh()` 写进框里），回车提交 → 派发 `Input Submit`。**框里正在打的字不同步进 content**：要用就直接读 `$self.control.text`（取值链能读实例成员）——于是提交没有"先收文本"这一步，**元素自己没有提交逻辑**，提交就是配置里的普通命令串（送到哪 + 清空 + 要不要退出编辑 + 刷改过的两个 UI）。**元素里没有任何特判**：点它进编辑也是一条普通配置（`[QName.mouseLeft, 'UIInteract.begin_edit $self']`，换成别的事件也行），事件照常走配置 + 冒泡 | `[[QName.mouseLeft, 'UIInteract.begin_edit $self'], [QName.input_submit, 'Utils.write "$UiSys.get_ui($self.parent.config.bind).config.content" $self.control.text\vUtils.write "$self.config.content"\vUIInteract.end_edit $self\v$UiSys.get_ui($self.parent.config.bind).refresh\v$self.refresh']]` |
- 组合控件（如带背景的按钮）直接用 `children` 配置堆叠（Panel 背景子元素 + Label 文字子元素），不写子类。
- 元素**不连接任何引擎信号**（含 `Button.pressed`、`LineEdit.text_changed` / `focus_exited` / `text_submitted`）：点击/拖动等全部由 PointerDetect 命中 → 事件 → `on_event` → 指令/消息 派发；引擎控件"自己才知道"的状态（框里的文字、编辑焦点）一律**按需直接读**（取值链读 `$self.control.text`）或走交互层那几个命令（`UIInteract.begin_edit` / `end_edit`；点别处由 `PointerDetect.key` 开头收掉）。输入链路唯一，那条"唯一链路"仍旧管游戏按键（`edit_ui` 期间不翻译按键）。

## PointerDetect（Script/Input/PointerDetect.gd）
- 两个入口：`_process(delta)`（刷新 hover，由 `InputSys._process` 在派发之前调——**一帧只检测这一次**）与 `key(status_name)`（把状态名当事件名派发给 hover 的 UI）；状态→SystemShortcut→指令那条链在配置里。
- **指针自己的三件事由 `_process` 直接派发**（不占状态、也不占快捷指令）：`Pointer Enter` / `Pointer Exit`（hover 变化时）与 `Pointer Move`（本帧 `InputSys.mouse_delta` 不为 0 时，即"这一帧动过"）。按键类事件仍走状态层 → `PointerDetect.key "<状态名>"`。
- **指针不锁定**：事件永远派发给"当前 hover 的 UI"。所以"按住期间还要继续做的事"（等比缩放）不能靠它，走 `AutoSys`（挂在状态上，与指针在哪无关，状态结束自动停）；也就不需要"把松开事件送到元素手上"这类机制。
- **命中沿 Godot 的控件树走**（`PointerDetect._ui_at`）：从 UI 根的孩子（窗口）**倒序**开始 → 每层 Control 也倒序（同级后画的在上面）→ 进一个 Control 先问它的孩子（孩子画在父之上），都不命中才算它自己。**不做"祖先矩形剪枝"**：自由定位元素（叠加层里那些）本来就画在父矩形之外，菜单还会伸出宿主，按父矩形剪掉子树 = 那些地方点不到（实测踩过：菜单被叠加层剪掉，点在菜单上却命中面板的文本）。反查 UIBase 用建控件时挂在 `control` 上的 meta（`UIBase.META_UI`），走到没挂 meta 的内部控件（PanelContainer/VBox/文本内部的 Label）就沿用外层那个元素。于是**命中顺序 ≡ 绘制顺序**，`uis` 只是"名字 → 实例"的字典（顺序无含义），`set_top` 也只需 `move_to_front()`。
- 用 `control.is_visible_in_tree()`：父 UI 关闭(hide)后子元素不再可命中。
- 命中矩形 `control.get_global_rect()` **含 `scale`**（实测：面板 `scale = 1.1` 时矩形宽高同步 ×1.1）⇒ 用 `UIInteract.resize` 缩放后，指针命中区自动跟着走，这里不用改。

## Config/UI/UIPreset_Basic.gd（extends ConfigBase）
```gdscript
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", {
        "position": [30, 30], "size": [320, 220],
        "children": [
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "events": [["Mouse Left", "UIInteract.drag $self.parent $event"]],
            }],
            # "按钮" = 文本元素 + "Mouse Left" 指令，无需 Button 子类
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [["Mouse Left", "UIInteract.close $self.parent"]],
            }],
            ["Info", "UI_Scroll", { "content": "初始内容" }],
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
]
```
- 组装读法：根 `UI_Panel` 含三个子元素——标题栏按住拖动父 UI、文本"按钮"关闭父 UI、滚动区展示内容；改展示内容只需写 `get_ui("MiniHUD/Info").config["content"]` 再 `refresh("content")`（见 Test.ui_test），或发 `Utils.write "$self.config.content" 值\v$self.refresh("content")` 指令。

## 右键菜单（Config/UI/UIPreset_Menu.gd 的配置 + 通用 UI 机制）
- **菜单没有专属类**：就是普通 `UI_Panel` + 三条配置（`open_at` / `close_on_blur` / `free`）——开启与失焦关闭都读配置统一处理（`UIInteract_OpenClose`：`_place` 管"开在哪"、`_blur_uis` 候选 + `close_blur_ui` 管"失焦关闭"），所以"换一套配置"就等于换一种菜单。菜单项就是它 `config["children"]` 里的普通子 UI，行为由子 UI 的事件绑定给出。
- **开启 = 开一个 UI（唯一入口 `UIInteract_OpenClose.open`，指令形式 `UIInteract.open`）**：整个开启逻辑（复用查找 `_child_ui` → 现建 `_build_open` → 摆位 `_place`）都在这个文件里，`UiSys` 只提供登记表与登记名规则。**挂哪由 anchor/host 决定**（见上面的挂载规则），摆在哪由**被开启 UI 自己配置里的 `open_at`** 声明：
  - `host` 为空 → 独立 UI 挂 UI 根，指令写成 `UIInteract.open --preset_name MiniHUD`（命名参数跳过 target）。
  - 有 `anchor`（多级菜单：触发它的那个菜单项）→ **挂在 anchor 下**，子菜单成为该菜单项的后代；只给 `host` → 挂在 host 下。
  - `Enums.OpenAt.CONFIG`（不写 `open_at` 时的默认）：摆回配置里的 `position`；`POINTER`：开在指针处（右键菜单——**仍然要传 anchor**，因为它决定挂在谁下面）；`ANCHOR_TOP_RIGHT`：开在 `anchor` 的右上角顶点（多级菜单把触发它的那个菜单项传进来）；`ANCHOR_TOP_RIGHT_IN` / `ANCHOR_BOTTOM_RIGHT_IN`：开在 `anchor` **内部**的右上角 / 右下角（按自己宽高内缩，关闭按钮与缩放手柄用的就是这两个）。
  - 位置换算（屏幕坐标 → 挂载点坐标系的 `position`）在 `UIBase.show_at`：**别用 `set_global_position`**（按当前全局变换求逆，重复摆会跟旧 position 复合、越摆越偏），**也别设 `Control.top_level`**（会失去父级可见性继承，宿主关掉后它还留在屏幕上、还能被命中）。
- **菜单链是一棵子树**：`Menu` 挂在宿主下、子菜单挂在"触发它的菜单项"下（`MiniHUD → Menu → Edit → MenuEdit`），所以菜单项里 `$self.parent` = 菜单本身，往上级数就是往上级 UI：`Menu` 的项用 2 级 = 宿主，`MenuEdit` 的项用 4 级 = 宿主（**链每深一层，到宿主多一级**）。菜单项的功能都作用在宿主上（"关闭"关宿主、"添加关闭按钮"给宿主加 X、"启用拖拽"拖宿主），菜单只是快捷方式——像右键窗口标题栏点"关闭"，关掉的是窗口。宿主一 `hide()`，整条链随之不可见、也不再被指针命中（可见性照常继承）。
- **失焦判定也因此变简单**：`UIInteract_OpenClose.close_blur_ui` 判"指针是否在我要的链上"，鼠标在子菜单上时沿 parent 链能走回父菜单，所以父菜单不会被误关。
- **触发**：宿主配置里写 `"events": [["Mouse Right", "UIInteract.open $self Menu $self"]]`；状态层只需 `Mouse Right → PointerDetect.key "Mouse Right"` 把事件派发给 hover 的 UI，**不需要系统级快捷**。
- **多级菜单 = 菜单开菜单**：菜单项的 `Pointer Enter` → `UIInteract.open $self MenuEdit $self`（第一个参数是挂载点，第二个是位置锚点，菜单项里都传 `$self`），层数不写死。
- **菜单项里的"开关"**（如 `MenuEdit/CloseToggle`）：普通 `UI_Label` 上写两套配置，`"Mouse Left"` 一条串里做三件事——`open <宿主> CloseButton <宿主>`（另一套里是 `close <宿主> CloseButton`）\v `Utils.swap "$self.config.events" "$self.config.events_2"` \v `Utils.swap "$self.config.content" "$self.config.content_2"` \v `$self.refresh("content")`，于是点第一次开关闭按钮、点第二次关它，文字也跟着换。关闭按钮就是 `Config/UI/UIPreset_Basic.gd` 里的普通预设（`open_at = Enums.OpenAt.ANCHOR_TOP_RIGHT_IN`：开在锚点**内部**右上角，按自己宽度内缩）。
- **关掉 = 隐藏（实例复用）**：关闭统一走 `UIInteract.close`（`hide()` + 广播）；**父 UI 一 hide，挂在它下面的子 UI 随可见性继承一起不可见**，所以不需要"关父菜单时连子菜单一起关"这种递归。`open` 按登记名查——有就"显示 + 重新摆位"，没有才现场创建；同一登记名只有一份，隐藏的实例不参与指针命中、也不算"开着"。
- **隐藏后怎么回来**：`close` 只是 `hide()`，实例还在 `uis` 里，所以重开不用重建——重开统一走 `UIInteract_OpenClose.open`（显示 + 按 `open_at` 摆位，不重建控件；指令形式就是 `UIInteract.open`）。**注意 `PointerDetect` 用 `is_visible_in_tree()` 判命中，隐藏的 UI 再也收不到任何事件**，所以重开的触发不能写在它自己身上（"再点一下"是点不到的），必须来自它仍可见的父级、或系统级的状态/快捷指令。
- **失焦关闭（两套，与"是不是菜单"无关）**：都由 open 登记候选、close 摘掉（只有"开出来的"才可能失焦，配置里的子元素不会单独关；关过再开自动回来）。
  - `close_on_blur`（**点关**）：有按键派发时判一次 ⇒ 指针不在它（或它的子孙元素）上就关。右键菜单用这种——鼠标划过不该把菜单关掉。
  - `close_on_move`（**移开关**）：指针一动就判 ⇒ 不在它（**或它的挂载点**）上就关。hover 展开的子菜单用这种——挪开就收。
    - 为什么要多算一层挂载点：子菜单开在触发项**旁边**（不在触发项的矩形里），指针通常还停在触发项上；只算自己的话，它一开出来就会被自己关掉。
  - **在哪写**：可以写进预设 config，但**推荐开的时候传参**（`--close_on_move`）——关闭行为只取决于"在哪开、为什么开"，写进预设等于每加一层子菜单都得记得抄一遍，漏一处那个 UI 就永远关不掉。
  - 点关的判定时机：`key()` 派发时只置标记（`PointerDetect._blur_pending`），判定放在**下一次命中刷新**的尾巴上。两个理由：① 判定的那一刻，菜单往往正在被这次派发 open 出来（右键开菜单），拿"上次刷新的 hover"判会把它当成"指针在外面"当场关掉（表现为"关过一次之后就再也开不出来"）；② 命中检测一帧只该有一次（`InputSys._process` 里那次，早于派发），派发完再刷一遍既白跑、又会让 enter/exit 在同帧里派发两次。移开关则挂在 `PointerDetect._process` 的"本帧位移不为 0"分支里（没动就不必重复判）。
  - **尺寸为 0 的先不判**（`get_global_rect()` 是退化矩形 ⇒ 会被误判成"指针在外面"）：布局还没跑时先当它"还在指针下"（多级菜单"一开就没"就是这么来的）。
    - 反过来说：**尺寸被谁压成 0 的 UI 会永远跳过判定 ⇒ 永远关不掉**。踩过这个坑：菜单（free 子元素）被挂进了 `ScrollContainer`（滚动容器会按视口改子节点尺寸），于是它高度 0、菜单既显示不全又关不掉。⇒ 自由定位的子元素必须挂"非容器"的叠加层（`UI_Panel` / `UI_Scroll` 都各有一个 `Overlay`）。

## 按名称绑定（复制名称 / 绑定 ▸）与重名后缀

- **要解决的问题**：一个 UI 把信息交给另一个 UI，而两者谁也不认识谁（不是父子、不在同一预设里）。中间记一个**名字**即可，不需要它们互相持有引用。
- **名字怎么来**：`UIBase._unique_child_name` —— 组装子元素时（配置 `children` 与运行时 `add_child_element` 两条路）都过一遍：
  **同一挂载点下重名就加 `_2`、`_3`…，没重名保持原样**（所以 `Title` 还是 `Title`，不会变成 `Title_1`）。
  判重看"本元素已有的子元素"，不查登记表（建树时父元素自己还没登记）。理由是登记名 = `挂载点登记名/名字` ⇒ 同名就是同一个登记名 ⇒ 互相覆盖。
- **流程**：右键目标 → "复制名称"（`copy_name`，复制的是**登记名**，如 `TestShow`、`MiniHUD/Title`，带后缀的真名）
  → 右键要收信息的 UI → "绑定 ▸"（`open … \v paste_copied_name $self`：普通 open 打开子菜单 + 预填刚复制的名字）→ 回车（`set_bind` 记进 `config["bind"]`）
  → 之后那个 UI 里发信息时用 `send_to_bind` 即可。
- **绑定名沿 parent 往上找**：绑定挂在面板上（右键面板 → 绑定 ▸），而发信息的往往是里面的元素（输入框）⇒ `send_to_bind` 自己 `config["bind"]` 没有就沿 parent 找，与事件冒泡同一套思路。
- 例子见 `Config/UI/UIPreset_Test.gd`（`TestShow` 显示 / `TestInput` 输入，J / K 键开关）。

## 键盘快捷键界面（Config/UI/UIPreset_Keyboard.gd）

- **一份配置搞定**：`values` 里只有一个 `Keyboard`（`UI_Panel`），103 个键的子元素由文件里的 `KEYS` 表**在 values 外算好**再由 values 引用（`_layout`）。
- `KEYS` 每列是 **[键码, x, 行, 尺寸, 显示文本]**（左右修饰键多一列 `KEY_LOCATION_LEFT/RIGHT`）：表中数值照抄 Unity 那版的原表达式（`32*2`、`row1 = -36*2`…），统一再乘一个 `SCALE`（表里数值保持与 Unity 一致，**要缩放只改 `SCALE`**）。`SCALE = 1.0` 就是与 Unity 同尺寸（面板 1600×576、键 64×64），比默认窗口 1152×648 大；想缩进小窗口就调小它（如 0.7 ⇒ 1120×403）。字号不跟着 `SCALE` 走，改完要自己看着调。
- **键码才是"这个键是谁"**（`KEY_ESCAPE` / `KEY_Q` / `KEY_KP_8`…），最后一列只是给人看的文本（"Esc"、"Space"）。以后"点某个键 → 把它绑到某操作"就是拿 `config["key_code"]`（+ `key_location`）造 `InputEventKey`。
  - 左右修饰键在 Godot 里 keycode 相同（Shift/Ctrl/Alt 各一对），靠 `InputEventKey.location` 区分 → 表里多一列位置，**元素名也随之带 `_L`/`_R`**（不带的话两个键会注册到同一个名字下互相覆盖）。
  - 元素名由键码字符串生成：`Escape→Key_Escape`、`Kp 8→Key_Kp8`、`Slash→Key_Slash`、`Shift+LEFT→Key_Shift_L`（生成时做重名检查并警告）。
- 每个键 = 一个 `free` 的 `UI_Panel`（绝对坐标定位，底图 `KEY_BG`，配置里带 `key_code` / `key_location`）+ 两个 `UI_Label`：`Name` 键名（Esc / Q …）、`Desc` 当前绑定的操作。**字号与字色都配在这两个文本上**（`font_size` / `font_color`）——不配字色就是主题默认的近白色，画在浅色键底上会看不见。
- **整块面板可拖动**：按住 → `UIInteract.drag $self $event` 登记 → 每帧 `dragging`（子元素没配这个事件时会冒泡到这里，与 MiniHUD 标题栏同一套）。
- **底图**走 `UI_Panel.background`（九宫格），面板与键共用 `Material/Texture/UI/RoundedIcon_32.png`；图片缺失只警告一次、改用默认面板样式，不影响运行。
- **以后给键绑操作**：改它的描述文本即可，登记名 = `Keyboard/键名/Desc`（键名由键码生成，如 `Keyboard/Key_Q/Desc`、`Keyboard/Key_Kp8/Desc`、`Keyboard/Key_Shift_L/Desc`）。
- **开启**：独立 UI，`UIInteract.open --preset_name Keyboard`；右上角的 "X" 就是普通预设 `CloseButton`（`open <键盘> CloseButton <键盘>`）——见 `Test.ui_test`。

## 消息（MessageHub.gd）
- `send_ui_create/remove(ui)` 与 `listen_ui_create/remove`。
- `send_ui_press/drag/release/submit/close/scale(ui)`、`send_ui_fade(ui, target)` 与对应 `listen_ui_*`：每个函数固定 action，id 为 `format_ID(["UI", str(ui.ID), action])`。
- 现在这些消息主要作为**未配指令元素**的默认出口；配了指令的元素改走 `Msg.send_cmd`。

## 已确认但暂缓 / 留空
- `PointerDetect` 已提供 `hover_char` / `map_position`，角色/地图的交互派发暂缓；`track_id`（UI 跟随角色）随开关一起移除，待需要时以指令形式回归（如 `UIInteract.follow $self.parent $@角色ID`）。
- 多套 UI 版本（横竖屏/字体缩放）、可视化编辑器、缩放指令（`UIInteract.scale`）。
- 更细的 style 默认值回退链（元素→父→UI 根→全局默认）后续按需补。
