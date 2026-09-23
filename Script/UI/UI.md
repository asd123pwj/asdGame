# UI · UI 界面系统

## 定位
UI 系统遵循项目统一范式（见 `设计文档.md` §二/§三/§十）：**UIPreset**（配置）→ **UISys**（管理脚本，文件 `UISystem.gd`）→ **UIBase**（元素基类）→ `Config/UI/` 配置类。
- `UIBase extends BaseClass`，**不直接继承 Control**：内部用变量持有 `control: Control`（真正的引擎节点），不用自定义 signal。
- **一个 UI = 多个基本元素的组装**：根元素（如 `UI_Panel`）由 config["children"] 声明子元素（都是 UIBase 子类），build 时递归组装。
- **交互 = 指令**：元素不再用 `draggable/closeable/...` 开关，而是"事件→指令"——`config["events"]` 是 `[事件名, 指令串]` 的列表，事件发生即发送对应指令；**事件名就是状态名**（统一来自 `QName`，如 `QName.mouseLeft`；UI 不感知键位，键位只在状态层配），hover 变化用 `QName.pointer_enter` / `QName.pointer_exit`；指令里 `@self.parent`(挂载对象)/`self`(自身) 在发送前替换为实例（`@注册名` 形式）。想要什么行为就配什么指令（拖动手柄配 drag 指令、关闭按钮配 close 指令）。**配置里指令串外层一律用单引号**（Godot 与 Python 一样两种引号都行）：里面要写双引号（路径/字符串参数）时就不必转义成 `\"`，写出来就是指令本身的样子。
- **显示内容统一是 `config["content"]`**（**没有同名成员变量**）：元素展示什么由它决定，改内容 = 写 `config["content"]`（`Utils.write("@self.config.content", 值)`）再在**下一条**接 `@self.refresh("content")`（只改了它这一项），不必重建控件。**路径参数写成带引号的字符串**：引号里的内容不再被当成取值式，路径原样传进函数。

## 目录与命名约定
```
Script/UI/
├─ UI.md                 # 本文档
├─ UIPreset.gd           # UI 预设（extends PresetRegister）：一条 UI 配置 + create_element 工厂
├─ UISystem.gd           # UI 系统（class_name UISys，extends BaseClass）：登记表 + 登记名规则 + 取件（成员全静态）
├─ Interact/             # 交互指令宿主：UIInteractBase 是基类（指令前缀 + 共用校验），一个交互一个文件
│  ├─ UIInteractBase.gd         # 基类：CMD_HOST（指令前缀，声明一次）+ _as_ui（组内共用校验）
│  ├─ UIInteract_OpenClose.gd   # open / close（含 _build_open / _place / _child_ui 与失焦关闭）
│  ├─ UIInteract_Drag.gd        # drag + 每帧 dragging
│  ├─ UIInteract_Rescale.gd     # rescale + 每帧 rescaling
│  ├─ UIInteract_Fade.gd        # fade_to
│  ├─ UIInteract_Edit.gd        # begin_edit / end_edit
│  ├─ UIInteract_Fold.gd        # fold / unfold / toggle_fold（收起 / 展开，见"长内容"一节）
│  ├─ （UI 编辑器没有专用交互：内容元素 UI_Editor.gd 自己铺，见"UI 编辑器"一节）
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
| `UISystem.gd` | UI 系统 `UISys`：**登记**整棵 UI 树（子元素一并登记；**开启**见 `UIInteract_OpenClose.open`），成员全静态，日常直接 `UISys.xxx`。 |
| `Interact/UIInteractBase.gd` | **交互组基类**：指令前缀（`const CMD_HOST := "UIInteract"`）+ 组内共用校验 `_as_ui`。交互按"一个交互一个文件"拆在 `Interact/` 下（`UIInteract_OpenClose.gd`、`UIInteract_Drag.gd`、`UIInteract_Rescale.gd`、`UIInteract_Fade.gd`、`UIInteract_Edit.gd`、`UIInteract_Fold.gd`、`UIInteract_SwitchValue.gd`、`UIInteract_SetTop.gd`，都 `extends UIInteractBase`），所以**对外只有一套指令名** `UIInteract.open/close/drag/rescale/fade_to/begin_edit/end_edit/fold/unfold/toggle_fold/switch_value/set_top`。元素自己的普通方法不必包成交互——指令系统能直接调：整行写 `@self.refresh("content")`（见下）。加一个交互 = 加一个 `UIInteract_Xxx.gd` + 静态方法，指令名自动是 `UIInteract.xxx`（机制见 `CmdSys` 的命令前缀组）。**开启（open + 摆位 + 子方法 + 失焦关闭）也在这个组里**（`UIInteract_OpenClose.gd`）。 |
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

## UISystem.gd（class_name UISys，extends BaseClass）
- **成员全是静态的**：`UISys.root`（UI 根 CanvasLayer）、`UISys.get_ui(登记名)`、`UISys.find_name(ui)`，调用直接写它们，不用经 `Sys.uiSys`（那个实例只用于启动时跑一次 `_init` 建 UI 根）。**登记表不在这里**：名字 ↔ 实例两张表都在 `RegSys`（见"注册名系统"一节）；**开启也不在这里**：见 `UIInteract_OpenClose.open`。
- **画在谁上面**：UI 根是 `CanvasLayer`，层号取 `UISys.ROOT_LAYER = 100`——**必须大于地图**（地图每个子层用自己的 `CanvasLayer.layer = 子层 id`，世界层 0 就是 0~5，以后加世界层还会更大），默认值 1 会被地图盖住。
- **挂载规则**（决定 UI 树 ⇒ 决定"关谁连谁一起关"和 `@self.parent` 的级数）：有 `anchor`（触发它的那个元素）→ **挂在 anchor 下**；没有 anchor → 挂在 `host` 下；都没有 → 挂 UI 根（独立 UI）。所以"菜单开子菜单"得到的是一棵**单链子树**：`MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`。
- **画在谁上面**：UI 根是 `CanvasLayer`，层号取 `UISys.ROOT_LAYER = 100`——**必须大于地图**（地图每个子层用自己的 `CanvasLayer.layer = 子层 id`，世界层 0 就是 0~5，以后加世界层还会更大），默认值 1 会被地图盖住。
- **点一下谁谁在最前**：`UIInteract_SetTop.set_top`（`PointerDetect.key` 里除"指针移动"外的派发自动调它，`open` 也调）。**提的是"窗口"不是被点到的小元素**——沿 `parent` 链爬到最外层那个 UI（挂 UI 根的那个）再排；直接对元素 `move_to_front()` 有两个后果：同级窗口没动（看着没生效）+ 元素在 VBox/PanelContainer 里重排兄弟 = 改布局（"子 UI 在面板里乱窜"）。爬完只需一句 `control.move_to_front()`：**命中已经和绘制同序**（见下），不用再维护登记表顺序。同一次按住里 HOLD 每帧派发，靠"最近提的是哪个窗口"去重。
- **登记名规则**（唯一的"寻址"约定，`RegSys.join`，**只有这一条**）：没有挂载点 → `UI/预设名`（`UI/MiniHUD`）；有挂载点 → `挂载点的登记名/名字`（`UI/MiniHUD/Menu`、`UI/MiniHUD/Menu/Edit/MenuEdit`）。**"开出来的 UI"与"配置里的子元素"共用它**（子 UI 的名字就是它的预设名），所以登记表是一整棵 `/` 连接的树；**"是否能复用"就是一次 `RegSys.get_(登记名)`**，不需要按类型遍历。同一挂载点下不要重名。
- `UIInteract.open(...)`：**全项目唯一的开启入口**（普通 UI 与菜单同一条路，不要再写第二个；签名见下面的指令表）。
  - `host` 为空 → 独立 UI：建预设自己那份 → 挂 `root` → 登记（登记名就是预设名，如 `MiniHUD`）→ `Msg.send_ui_create`。
  - 给了 `anchor` / `host` → 深拷贝模板 → `挂载点.add_child_element` 挂到它下面 → **登记名 = `挂载点登记名/预设名`**（如 `MiniHUD/Menu`、`MiniHUD/Menu/Edit/MenuEdit`）；两者都不给则挂 UI 根、登记名就是预设名。
  - 已存在就**只显示 + 重新摆位**，不重建控件——"是否存在"就是一次字典查找 `uis.get(登记名)`（命名规则见 `UISys` 文件头），**没有任何按 UI 类型的特判**。
  - 子元素也要登记，是为了 **PointerDetect 能把指针命中派发到具体子元素**（如关闭按钮、菜单项）；命中顺序**沿控件树倒序**走（同级后画的在上面、孩子先于父，见 `PointerDetect._ui_at`），不再看登记顺序。
- `get_ui(登记名)`：按名取（子元素用全名，如 `MiniHUD/Info`）——就是 `RegSys.get_(名字)` 加一层 UIBase 类型。
- `find_name(ui)`：反查"这个 UI 叫什么"——`RegSys.name_of` 的 UI 版。
- `register_child(parent, child)` / `_register_tree(ui, 全名)`：**按 UI 树递归登记**（顺着父元素的 `children` 一层层走，登记名 = `RegSys.join(挂载点, 名字)`）。**"名字怎么拼"不在这里**，在 RegSys（下一节）；这里只管"UI 树怎么递归"。
- **删掉动态子树**是 `UIBase.clear_children()`（整排）/ `remove_child_element(ui)`（摘一个）/ `replace_child_element(old, 名, 类, 配置)`（**原地换一个**）：
  递归摘注册名 → 立刻脱离控件树 → 释放控件；**谁动态铺了内容谁自己调**（`UI_Editor.rebuild`、`UI_Status.reload` / 重铺一段），不劳 UISys。
  **只重铺其中一块要用"原地换"**：摘掉再加会把它排到最底下（`children` 与容器里都到末尾）——"状态一变那行就跳到最后"就是这么来的。
- **"给某个 UI 加/减东西"= 开/关一个预设 UI**：不再有 `add_close_button` / `remove_close_button` 这类成对的专门函数（那正是"同一需求两套策略"）。关闭按钮就是一个普通预设 `CloseButton`（`Config/UI/UIPreset_Basic.gd`，`open_at = ANCHOR_TOP_RIGHT_IN` 开在锚点内部右上角），加它 = `UIInteract.open(宿主, "CloseButton", 宿主)`，减它 = `UIInteract.close(宿主, "CloseButton")`。
- **缩放手柄**同样是普通预设 `ResizeButton`（图标 `content` + `open_at = ANCHOR_BOTTOM_RIGHT_IN` 开在锚点内部右下角），**只有一条事件**，而且不直接调缩放函数，而是交给 `AutoSys`：
  ```gdscript
  "events": [["Mouse Left", "UIInteract.rescale @self.parent event"]],
  ```
  读作：按住时调 `rescale` 登记（`event` = 触发它的事件名 = 状态名）；之后每帧由 AutoSys 调 `rescaling <手柄挂着的那个 UI>`；松手（状态不满足）时 AutoSys 自己把这条登记删掉——**所以不用写"松开"**。两者都声明了 `free`（否则会被宿主的竖排布局排走）。
  - 用 `Hold` 而不是 `Press`：**状态层只在"满足状态变化"时广播**，所以 Hold 只在"开始按住"那一下触发一次——正好用来做"登记"；之后的每帧由 AutoSys 驱动，不需要带 `| Tick` 的状态。
  - 状态名不在配置里重复写：`event` 由**指令系统**换成带引号的触发事件名（状态名统一来自 `QName`，见 `Config/QuickName.gd`）。
- **`AutoSys`（Script/Auto/Auto.md）——按住类交互为什么需要它**：等比缩放必然让手柄离开指针（缩小时手柄往里跑、放大时往外跑），而事件默认按 hover 派发 → 指针一离开，事件就断，表现就是"横向还行、纵向停住"。AutoSys 把"每帧做什么"挂在**状态**上（状态满足与指针在哪无关），状态一结束就自动删登记，所以：元素侧只写一条事件、不用捕获鼠标、不用手工退订、也不用存跨帧状态。
- **按住类指令一律成对**：`rescale`/`drag` 是**登记入口**（配置里写它们，内部用 `Callable.bind` 把活交给 AutoSys，不拼指令串），`rescaling`/`dragging` 是**每帧执行**（不写配置）。`rescale` 的算法是增量式的（`scale *= |指针-左上角| / |上帧指针-左上角|`），所以既不需要"记录抓手位置"（按下不跳变），也不需要注册/注销回调。
- **只管生命周期，交互实现都在 `UIInteract`**。

## 注册名系统（RegSys，Script/System/RegSystem.gd）

- **要解决的问题**：config 里存的是**名字**（字符串，如 `UI/MiniHUD/Menu`，见 `host`），
  但名字给人看能认出来，编辑 / 排错时一眼知道是谁；反过来"敲一个名字、要拿到那个实例"也需要一条路。
  ⇒ 需要"名字 ↔ 实例"两张表。
- **两张表一起维护**（成员全静态）：`_to_obj`（注册名 → **实例**）、`_to_name`（实例 → 注册名）。
  **只认名字**：ID 每次运行都不一样、写盘也存不住，所以"指到某个实例"一律用注册名（`@注册名`、`config["host"]`）。
  **UI 的注册名带 `UI/` 根前缀**（`UI/MiniHUD`、`UI/MiniHUD/Menu/Close`）——独立 UI 就是 `UI/预设名`
  （见 UIInteract_OpenClose.UI_ROOT），于是"这是 UI 还是别的东西"从名字上分得清。
  入口：`register(obj, 名字, dedup=false)`（**返回真正用上的名字**）/ `unregister(obj)` / `get_(名字)`（名字→实例）/
  `name_of(实例)` / `has(名字)` / `join(父, 名字)` / `names()` / `clear()`。
- **表里存的就是实例本身**（`_to_name` 的键 = 实例）：于是"同一个实例只有一个名字"天然成立；
  实例没了就查名字得空串、查实例得 null（本系统不背生命周期，动态删之前先 `unregister`）。
- **层级名只有一条写法**：`RegSys.join(父, 名字)` = `父名/子名`（父没登记就只用名字）——
  UI 树用它，以后别的树（角色 / 地图层…）照抄即可，于是"名字长什么样"只有一处。
- **谁在用**：`UISys._register_tree` 登记整棵 UI 树（顺手把登记名写进 `config["reg_name"]`，于是
  "这个 UI 叫什么"是读值能拿到的数据）；指令系统按注册名取实例（`@注册名`）；UI 编辑器直接把 `host`
  这类键当名字显示 / 编辑（写进去就是名字本身，见 UI_Editor）。
- **撞名**：后来者覆盖并警告一声（UI 的"同一挂载点下不要重名"就是这么来的）。

## UIBase.gd（extends BaseClass）
- `var control: Control`；`build()` = `_create_control()` → `_apply_config()` → `refresh()` → `_build_children()`。
- **两个生命周期钩子**（默认什么都不做，需要"知道自己被登记好 / 被开出来 / 被关掉"的元素覆写）：
  - `on_registered()`：登记完名字之后叫（子元素登记要父级名字 ⇒ 元素要等自己有名字才能铺内容，如 `UI_Editor`）；
  - `on_shown()` / `on_hidden()`：`UIInteract.open` 摆好位显示之后 / `close` 隐藏之后叫，**整棵子树都收到**
    （`UIBase.dispatch_shown / dispatch_hidden` 递归）。元素据此开关自己的开销（如 `UI_Status` 只在这时
    订阅 / 退订那些状态消息）。**为什么要有它**：重开一个已存在的 UI 是"复用 + 显示、不发消息"，
    只靠 `listen_ui_close` 那种消息盖不到这一半。
- **`config["content"]`（只是一个配置键，没有成员变量）**：显示内容（子类解释：Label=文本、Scroll=多行文本、Image=纹理路径）。子类覆写 `refresh(key)`，在里面读 `config.get("content")` 刷到控件。**不做成属性 set 自动刷**：要拦的会是整张 config（还有 events/size/…），而 config 是 Dictionary、拦不住写入——换成带 `_set/_get` 的对象则读点全要改，不划算。所以统一"**写 config + 紧跟一条 `@self.refresh("content")`**"。
- **`var parent: UIBase`**（挂载对象）：组装子元素时由父元素注入，是 `@self.parent` 的指向。
- **`var children: Array[UIBase]`**：按 `config["children"]`（每项 `[child_name, ui_class, child_config]`）组装，挂到 `_content_box()`（容器类覆写返回内部布局节点）。
- **事件→指令**：唯一入口 `on_event(事件名)`（由 PointerDetect 派发）：
  - 事件名就是**状态名**（统一来自 `QName`，见 `Config/QuickName.gd`）——**UI 不感知按键**，键位只在状态层 `statuses` 的 `keys` 里配置；hover 变化不对应状态，用 `QName.pointer_enter / QName.pointer_exit`。
  - 在 `config["events"]`（`[事件名, 指令串]` 列表）里**按等值**取指令串 → 派发前把"当前元素 + 事件名"告诉指令系统（`CommandParser.event_ui` / `event_name`），再 `Msg.send_cmd(指令串)`；
  指令串里的 `@self` / `@host` / `@event` 由**指令系统**自己解析（`UIBase` 不再扫字符串）。
  - 用列表而非字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），加新事件只需加一项。
  - 自己没配的事件**冒泡给父级**，冒泡到根都没有才什么都不做（元素没有隐式行为）；于是"整块面板的行为"在子元素上同样生效（如菜单面板启用拖拽后，按住菜单项也能拖），`self/@self.parent` 以"配了指令的那个元素"为基准。
- **运行时增改**：`add_child_element(child_name, ui_class, child_config)` 加子元素（内部交给 `UISys.register_child` 登记，登记名 = `挂载点登记名/名字`，登记后才可被指针命中）；对调两项配置用 `Utils.swap`（`Utils.gd`，两条路径写出来）、`switch_value(键, 值)` 在一个列表里"有就删、没有就加"（两者都是开关式按钮的底座：菜单的"启用关闭按钮"用前者、"启用拖拽"用后者——直接开关宿主 `events` 里的那一条绑定，不必预摆两套）。"关闭按钮"连新指令都不需要：它是普通预设 `CloseButton`，用 `open` / `close` 开关。
- **开关式按钮（可选框）**：不需要专门元素——同一个元素上放两套配置（`events` / `content` 与 `events_2` / `content_2`），点击时"做事 + `Utils.swap` 对调"，下次点击自然走另一套；**只加减一项**（如给宿主加/减一条绑定）用 `switch_value`，连第二套配置都不用写。事件串里多条命令用 `\v` 分隔（见 `CmdSys.execute`）。
- **改完 config 让界面跟上**：`refresh(键)` 管 content / visible（子类刷到控件上）；`reapply()` 管"**只有应用时才生效**"的那几项（`size` / `font_size` / `font_color` / `background`）。**两者都不碰 position**——位置会被拖动这类运行期行为偏离，改别的键不该把窗口拽回配置里那个位置；要按配置摆回去得显式 `refresh("position")`。编辑器改配置（`UI_Editor`）就是 `reapply()` → `refresh()` → `_fit_size()` 三步。
- **config 可选属性**：`position` / `size` / `content` / `children` / `events` / `visible` / `free`（自由定位：挂到叠加层的非容器挂载点，`position`/`size` 不被父级布局覆盖，用于"右上角的关闭按钮""菜单""键盘的每个键"这类元素）；`collapsed`（父元素）/ `collapse_keep`（子元素自己标"收起时留我"）不是 UIBase 读的，是**收起/展开交互**（`UIInteract.fold`）读的，见"长内容与收回 / 展开"一节。**配置子元素与运行时加的子元素共用这条规则**（`_build_children` 与 `add_child_element` 一致）：配了 `free` 就进叠加层任意摆，没配才进内容盒（容器类 = 竖排）。
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
    - **补完还会把结果发布成控件的最小尺寸**（`custom_minimum_size`）：本元素的根控件是普通 `Control`，它自己不汇总内容最小尺寸，而"面板套面板"（容器里的 `UI_Panel`，如可折叠分组）要靠这个最小尺寸才能往外撑——不发布的话内层面板在父容器眼里高度永远是 0，整棵子树都长不出来（做"可收回分组"时实测踩到：嵌套分组的高度一直停在标题那一点）。所以 `_fit_size()` 读"配置想要多大"要读 `config["size"]`（`_config_size()`），不能读 `custom_minimum_size`（那个值已被覆盖成"内容实际多大"）。
  - **`UI_Panel` 的 `_content_size()` 必须问内部的 `PanelContainer`，不能问根控件**：根是普通 `Control`，**不会汇总子元素的最小尺寸**，问它只会得到 `custom_minimum_size`（`[150, 0]` → 高度就是 0）。而且建时还没进树、字体主题都问不出来，所以要挂在 `_panel.minimum_size_changed` 上再补一次。
  - 指令串参数：**只有中间带空格时才需要引号**（如 `"Mouse Left | Tick"`），其余直接写名字（如 `open_menu self Menu`）。
  - **自由定位元素不要设 `Control.top_level`**：那会让它不再继承父级可见性（宿主 `hide()` 后它还留在屏幕上、也还能被命中）。摆放时把屏幕坐标换算成**宿主坐标系的 `position`**（挂载点原点即宿主原点）；也不要用 `set_global_position`——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏。
- **只存"何时发什么指令"**：无 `close()/fade_to()` 等交互实现（都在 `UIInteract`），无 `draggable/closeable/...` 开关。

## 交互指令（Script/UI/Interact/UIInteract_*.gd，静态方法 → 指令，前缀统一是 `UIInteract`）
- **这些都是纯副作用指令（`-> void`）**：只做 close/hide、改 position、起 Tween、转发消息，不返回值。因此被指令系统调用时不会在 `send_cmd` 的结果数组里多套一层，无需 `[0]` 剥离。
- **参数类型 `target: UIBase`**：指令里的 `@self.parent` / `self` 由**指令系统**转成 `@注册名`，执行取值链时按注册名取出**实例**再传入，所以这里收到的必然是 UIBase，不是名字。
- **`_as_ui(target, cmd_name)`**：只做校验、不再做"名字→实例"归一化（该路径已由指令系统承担）。target 为空、或目标尚未 `build()`（`control == null`）时 **`push_warning` 指明是哪个指令**，而不是静默 return——避免配置/组装写错却无提示。
- **占位符解析（`@self` / `@host` / `@event`）**：由**指令系统**在派发前解析——**只认三个词**（实现见 `CommandParser`）：
  - `self` → 自身（`@注册名`）：链尾接着写取值链，交给指令系统按表达式解析——`@self.parent`→父 UI（挂载对象）、`self.config.content`→自身显示内容。
  - `host` → **本条链的管理对象** → `@注册名`（解析见 `UIBase._find_host`）：从自己往上，**最近一个在 config 里写了 `host` 的元素**说了算（**注册名**）；谁都没写就回退到**最外层 UI**（窗口本身）。**"管理对象"的唯一写法**：菜单项 / 深层子元素不必再数 `@self.parent` 级数——中间套多少层（比如给菜单项再加一个可折叠分组）都指向同一个对象；而且管理对象**可以是任意一层 UI**（不一定是顶层）：开的时候给（`UIInteract.open(..., host=@self)`，或任何算得出实例的取值链），或运行中改（`Utils.write("<某个 UI 的路径>.config.host", "UI/MiniHUD/Menu")`——写成谁就以谁为界，它下面的整棵子树都跟着）。**存的是注册名**（字符串：可读、能存盘、跨运行也对得上，见 RegSys）：config 是数据（会被深拷贝、可能写盘成 json），实例存不进去；取不到时当"没声明"处理并提醒一次。
  - `event` → 触发事件名（**自带引号**，因为事件名里常有空格）。
  三个词在**路径字符串里也一样换**（`Utils.write("@self.config.content", 值)`、`Utils.write("@host.config.content_cmd", 值)`）。**紧跟 `=` 的词不换**：那是 `名字=值` 里的**参数名**——`UIInteract.open(…, host=@self)` 的 `host` 是"要传给哪个参数"，不是占位符（换掉的话指令系统按名字匹配不到，那条参数会被当"命名参数后面的位置参数"丢掉；实测踩过：菜单的 host 一直是 null，行为靠"回退最外层窗口"才看着对）。**没有 `$parent` / `$text` 这类专用占位符**（能从这三个词取到的就不另立语法；取不到时表达式给 null，由目标指令自己警告）。它是 `on_event` 的私有助手，放在 `UIBase` 里（没有第二个使用者）。
**指令语法：一行 = 一个表达式**（和写函数调用一样，参数一律包在 `()` 里）：
- `类.静态方法(参数, 名字=值)`：命令调用（命令只挂在"类.静态方法"这个命名上）。位置参数按签名顺序；**`名字=值` 可以跳过中间那些带默认值的参数**（像 Python 的关键字参数）；**不写的参数用签名里的默认值**。没有 flag 语法——bool 参数就写 `名字=true`。
- 取值链（`@self.control.text`、`Test.int1`、`@注册名.xxx`）：末尾带 `()` 就"调完拿返回值"（`@self.refresh("content")`），不带 `()` 就取这个值本身。**忘写 `()` 会警告**（取到的是函数本身，不是调用结果）。
- 普通路径 / 字面量：`Test.int1`、`5`、`"abc"` 也都是取值——**不再需要 `&`**。
- 字符串参数用双引号包住（`Utils.write("@self.config.content", 值)`）：引号里的 `$` 不会被当成取值式；数组字面量写 `[a, b, c]`。
- 例：`UIInteract.open(@self, "Menu", @self, close_on_blur=true)`、`Utils.swap("@self.config.content", "@self.config.content_2")`。
| 指令 | 作用 | 典型配置 |
|---|---|---|
| `UIInteract.close @self.parent` | 关闭（隐藏）目标 UI（发 `Msg.send_ui_close` + hide） | 关闭"按钮"的 press |
| `UIInteract.open([挂载点], 预设名, [锚点], close_on_blur=?, close_on_move=?, host=?)` | 开启/重开一个 UI（显示 + 按 `open_at` 摆位；不重建控件）。**锚点同时是挂载点**（子菜单挂到触发它的菜单项下）；挂载点与锚点都不给 = 独立 UI（`UIInteract.open(preset_name="MiniHUD")`）。`close_on_move=true` = 指针挪开就收（hover 展开的子菜单）、`close_on_blur=true` = 有按键派发时不在它上面就关（右键菜单）——**要哪种就在开的这一句写出来**，预设里不声明它（"在哪开、为什么开"只有这一句知道）。`host` = 这次开的 UI **要管理的对象**（见 `host` 占位符那行）：不给就沿链回退；**它不是挂载点**，挂哪/摆哪仍由前三个参数 + `open_at` 决定。复用路径也会更新这些指向 | 面板右键开菜单：`UIInteract.open(@self, "Menu", @self, close_on_blur=true)`；改管某个子 UI：`open(@self, "Menu", @self, host=UISys.get_ui("UI/MiniHUD/Info"))` |
| `UIInteract.drag(@host, @event)` | **按住拖动**（登记入口）：把"每帧拖 host（那个窗口）"挂到这个按住状态上，松手自动停 | MiniHUD 标题栏、整块键盘面板 |
| `UIInteract.rescale(@host, @event)` | **等比缩放**（登记入口）：每帧 `scale *= |指针 - 面板左上角| / |上帧指针 - 面板左上角|`（增量式，以左上角为中心，上下限取 `SysCfg.resize_min_scale / resize_max_scale`） | 缩放手柄 `ResizeButton` |
| `host` | 占位符，由**指令系统**换成**本条链的管理对象**的 `@注册名`："最近一个在 config 里写了 `host`（**注册名**）的元素"说了算，谁都没写就回退到**最外层 UI**（窗口）⇒ 管理对象可以是**任意一层 UI**（不必顶层），指令里也不必数 `@self.parent` 级数；路径字符串里也能用（`"@host.config.content_cmd"`）。写法：`UIInteract.open(..., host=@self)`（开的时候给）或 `Utils.write("<某个UI>.config.host", "UI/MiniHUD/Menu")`（运行中改，以声明处为界），也可以在UI 编辑器里直接把那一行改成 `MiniHUD/Menu`。**两种都用不了**（UI 已释放 / 名字没登记 / 写的不是个名字）⇒ 当没声明处理 + 提醒一次 | `UIInteract.close(@host)`、`Utils.copy(@host.config.reg_name)` |
| `event` | 占位符，由**指令系统**换成**带引号的触发事件名**（= 状态名 = Key 名），所以配置不必再抄一遍状态名 | 上面两条都在用 |

> 按住类交互在代码里成对写：`drag`/`rescale` 是**登记入口**（配置里写它们），
> `dragging`/`rescaling` 是**每帧执行**（不写配置，只由 `AutoSys` 调）。见 `Script/Auto/Auto.md`。
| `UIInteract.fade_to @self.parent 0.0 0.5` | 透明度渐隐/渐显（alpha, duration；**指令调用须写全参数**） | 提示淡出 |
| `Utils.write("<路径>", <值>)` | **通用的"按路径写值"**（`Utils.gd`，两个参数：路径里已带宿主）：路径语法与取值式**完全一致**（`self.config.content`、`@host.config.content_cmd`、`@注册名.config.content`、`Test.int1`、`a.b[0].c`、`UISys.get_ui(名字).config.content`——多层、列表下标、函数头都行），走的就是指令解析器（`CommandParser.write`）。**路径要写成字符串参数**（`"@self.config.content"`：引号里的内容不会被当成取值式）。**只写数据、不刷新界面** ⇒ 改完接一条 `@self.refresh("content")` | `Editor（内容对象）` 回车：`Utils.write("@host.config.content_cmd", @self.control.text)` |
| `Utils.swap("<路径A>", "<路径B>")` | 通用的"两项对调"（字典键 / 实例成员 / 类脚本静态都行），开关式按钮的底座；**界面刷新不在这里** ⇒ 改完接一条 `@self.refresh("content")` | 菜单 CloseToggle：`Utils.swap("@self.config.events", "@self.config.events_2")` |
| `Utils.copy(<文本>)` | 把文本复制到**系统剪贴板**（平台不支持会警告）。名字靠取值链取：`Utils.copy(@host.config.reg_name)` | 右键菜单"复制名称" |
| `@self.refresh("content")` | **调用**（整行 = 做事，末尾是方法就调它；`()` 里可以带参数）：刷新界面不用包一条交互——指令系统本来就能调方法，`refresh(key)` 是 `UIBase` 上的普通方法（子类继承自然生效）。**改了什么就刷什么**：只改了 content 就传 `"content"`，一次改了好几项 / 不确定才不传 key（全刷）。目标算出来的也能调：`UISys.get_ui(@host.config.content_cmd).refresh("content")` | `Utils.write("@self.config.content", 值)\v@self.refresh("content")` |
| `UIInteract.begin_edit @self.parent` | 让目标开始编辑（`UI_Input`：抢焦点 + 置 `InputSys.edit_ui`）——"打开后直接就能打字"用它 | `open … \v begin_edit …` |
| `UIInteract.end_edit(target)` | 让目标结束编辑（清 `InputSys.edit_ui` + 放焦点）。**"提交后要不要退出编辑"由配置决定**：要退出就写它；搜索框那种"提交完继续打字"就别写 | `Utils.write(…)\vUIInteract.end_edit(@self)\v…refresh("content")` |
| ~~`UIInteract.swap_config`~~（已退役） | 对调两项改用 `Utils.swap`：两条路径直接写出来，后面接一条刷新（换的是自己那两项就 `self`）——**开关式按钮就靠它 + 多命令实现** | `Utils.swap "@self.config.content" "@self.config.content_2"\v@self.refresh("content")` |
| `UIInteract.switch_value(target, 键, 值)` | 在 `config[键]` 列表里开关一个值：**已有（按内容比）就删、没有就追加**；`值` 可以是变量（如 `QName.UI_event_mouseLeft_drag`）。`events` 这类列表在派发时才读，所以改完立刻生效 | 菜单"启用拖拽"：往宿主 `events` 里加/减一条拖动绑定 |
| `UIInteract.set_top @self.parent` | 把 target 所在的**窗口**（沿 `parent` 爬到最外层那个 UI）提到最前：只需一句 `control.move_to_front()`——命中已与绘制同序（见下），不用再维护登记顺序。**一般不用写**：`PointerDetect.key` 里"点它"就会自动调（`open` 也会调，新开的排最前） | 点一下谁谁在最上面 |
| `UIInteract.close([宿主], [预设名])` | 关闭（隐藏）：**不写预设名 = 关 target 自己**；写了 = 关"挂在 target 下的那个预设 UI"（按"挂载点 + 预设名"查，没开过就什么都不做）。与 `open` 成对：给某个 UI 加/减东西 = 开/关一个预设 | 关闭"按钮"、开关式按钮的"移除"一侧：`UIInteract.close(宿主, "CloseButton")` |
| `UIInteract.toggle([目标], [预设名])` | **开关**：现在显示着就关、否则开（开/关都走本文件那两条，复用与摆位照旧）。键状态只在"满足变化"时给一次，写两条指令做不到判断该开还是该关，所以要有它 | `J → UIInteract.toggle(preset_name="TestShow")` |
| `UIInteract.fold(target, collapsed=?)` / `UIInteract.unfold(target)` / `UIInteract.toggle_fold(target)` | **收起 / 展开**（隐藏子元素，不是关闭）：收起只留子元素里**自己标了 `collapse_keep = true`** 的，其余 `hide()`；不可见的子元素不参与布局 ⇒ 容器按内容收缩（"高随内容"的面板自己变短），实例还在。状态记在 `config["collapsed"]`。见"长内容与收回 / 展开" | 收回按键：`UIInteract.toggle_fold(@self.parent)`\v`Utils.swap` 换文字 |
| （UI 编辑器没有专用指令） | 打开 = 一条通用 `UIInteract.open(@host, "Editor", @host, host=@host)`；内容由元素 `UI_Editor` 在登记完成时自己铺；展开某段 = 折叠交互的通用"按需建"；"[重建]"= 内容第一行 `@self.parent.rebuild()` | 见"UI 编辑器"一节 |
| （改一项配置**没有专门指令**） | 编辑器每行自带：`Utils.write` 把输入框的字**按文本→值**（`CommandParser.parse_value`：算不出就按原样字符串、空文本 = `null`）写回那条路径，再 `reapply()` + `refresh()` + `_fit_size()` 让界面跟上（见 `UI_Editor`） | 见"UI 编辑器"一节的"改完怎么生效" |

## 原子元素（Script/UI/UI/）
| 类 | 职责 | 事件配置示例 |
|---|---|---|
| `UI_Panel` | 面板容器：PanelContainer+Margin+VBox，子元素竖排；自身无功能逻辑。`background` 可给整块面板铺一张九宫格底图。配 `scroll: [上限宽, 上限高]`（0 = 该维不限制）时内容装进滚动容器：面板按"内容需要 ↔ 上限"取小，长出来的部分进去滚动（见"长内容"一节的"面板滚动"） | — |
| `UI_Label` | 文本：content 即文本；**绑 `"Mouse Left"`（按住）即"按钮"/"拖动手柄"**（配 `UIInteract.drag @self.parent event` 就是后者），要"按下那一下"就用 `"Mouse Left | Press"`（无需单独 Button 类） | `["Mouse Left", "UIInteract.close @self.parent"]` |
| `UI_Image` | 图片：content = 纹理路径，refresh 时 load；改图 = 写 `config["content"]` + 一条 `self.refresh` | — |
| `UI_Scroll` | 滚动容器：content 为多行文本，内层 Label autowrap。**ScrollContainer 默认最小尺寸为 0，必须用 `size` 配置可视区大小，否则不可见**。结构与 `UI_Panel` 同一套：`root(Control) → Scroll(ScrollContainer) → Label` + `Overlay(Control)`，**free 子元素挂 Overlay**（不能挂在滚动容器里：会被裁、尺寸被压成 0） | — |
| `UI_Input` | 输入框（LineEdit）：content 是**配置里写的初值**（`refresh()` 写进框里），回车提交 → 派发 `Input Submit`。**框里正在打的字不同步进 content**：要用就直接读 `@self.control.text`（取值链能读实例成员）——于是提交没有"先收文本"这一步，**元素自己没有提交逻辑**，提交就是配置里的普通命令串（送到哪 + 清空 + 要不要退出编辑 + 刷改过的两个 UI）。**元素里没有任何特判**：点它进编辑也是一条普通配置（`[QName.mouseLeft, 'UIInteract.begin_edit self']`，换成别的事件也行），事件照常走配置 + 冒泡。配 `multiline: true` 时控件换成 TextEdit：**自动换行 + 高度按"折行后的行数"自适应**（`max_height` 封顶，超出框内滚动），**回车仍是提交、不会插换行**（输入层判"这次算提交"就吃掉那个事件；按着 Shift 才留给 TextEdit 插换行） | `[[QName.mouseLeft, 'UIInteract.begin_edit self'], [QName.input_submit, 'Utils.write "@self.config.send_to" @self.control.text\vUtils.write "@self.config.content"\vUIInteract.end_edit self\v@self.refresh("content")\vself.refresh']]` |
- **一览类元素**（把运行期数据铺出来看）：`UI_Status`（角色状态）、`UI_Shortcut`（角色快捷）、`UI_Attr`（角色属性 / buff）——
  三者共用底座 **`UI_View`**（"看哪个角色（查看项 `content_cmd` 优先、其次自己的 `char`）/ 推迟一帧铺 /
  换对象自动重铺 / 开着才订·关掉全退·重开订回"都在它那儿；子类只实现 `_fill` 与 `_listen`）。
  外壳预设各一份（`UIPreset_Status` / `UIPreset_Shortcut` / `UIPreset_Attr`），打开都是
  `UIInteract.open(preset_name="…")`，换人写 `content_cmd="@Char/人类"`（再点 `[刷新]`）。
  为什么内容交给元素而不是写在外壳预设里：一个角色有哪些状态 / 快捷 / 类别，全是**运行期**才知道的。
- 组合控件（如带背景的按钮）直接用 `children` 配置堆叠（Panel 背景子元素 + Label 文字子元素），不写子类。
- 元素**不连接任何引擎信号**（含 `Button.pressed`、`LineEdit.text_changed` / `focus_exited` / `text_submitted`）：点击/拖动等全部由 PointerDetect 命中 → 事件 → `on_event` → 指令/消息 派发；引擎控件"自己才知道"的状态（框里的文字、编辑焦点）一律**按需直接读**（取值链读 `@self.control.text`）或走交互层那几个命令（`UIInteract.begin_edit` / `end_edit`；点别处由 `PointerDetect.key` 开头收掉）。输入链路唯一，那条"唯一链路"仍旧管游戏按键（`edit_ui` 期间不翻译按键）。

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
                "events": [["Mouse Left", "UIInteract.drag @self.parent event"]],
            }],
            # "按钮" = 文本元素 + "Mouse Left" 指令，无需 Button 子类
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [["Mouse Left", "UIInteract.close @self.parent"]],
            }],
            ["Info", "UI_Scroll", { "content": "初始内容" }],
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
]
```
- 组装读法：根 `UI_Panel` 含三个子元素——标题栏按住拖动父 UI、文本"按钮"关闭父 UI、滚动区展示内容；改展示内容只需写 `get_ui("UI/MiniHUD/Info").config["content"]` 再 `refresh("content")`（见 Test.ui_test），或发 `Utils.write "@self.config.content" 值\v@self.refresh("content")` 指令。

## 右键菜单（Config/UI/UIPreset_Menu.gd 的配置 + 通用 UI 机制）
- **菜单没有专属类**：就是普通 `UI_Panel` + 三条配置（`open_at` / `close_on_blur` / `free`）——开启与失焦关闭都读配置统一处理（`UIInteract_OpenClose`：`_place` 管"开在哪"、`_blur_uis` 候选 + `close_blur_ui` 管"失焦关闭"），所以"换一套配置"就等于换一种菜单。菜单项就是它 `config["children"]` 里的普通子 UI，行为由子 UI 的事件绑定给出。
- **开启 = 开一个 UI（唯一入口 `UIInteract_OpenClose.open`，指令形式 `UIInteract.open`）**：整个开启逻辑（复用查找 `_child_ui` → 现建 `_build_open` → 摆位 `_place`）都在这个文件里，`UISys` 只提供登记表与登记名规则。**挂哪由 anchor/host 决定**（见上面的挂载规则），摆在哪由**被开启 UI 自己配置里的 `open_at`** 声明：
  - `host` 为空 → 独立 UI 挂 UI 根，指令写成 `UIInteract.open(preset_name="MiniHUD")`（命名参数跳过 target）。
  - 有 `anchor`（多级菜单：触发它的那个菜单项）→ **挂在 anchor 下**，子菜单成为该菜单项的后代；只给 `host` → 挂在 host 下。
  - `Enums.OpenAt.CONFIG`（不写 `open_at` 时的默认）：摆回配置里的 `position`；`POINTER`：开在指针处（右键菜单——**仍然要传 anchor**，因为它决定挂在谁下面）；`ANCHOR_TOP_RIGHT`：开在 `anchor` 的右上角顶点（多级菜单把触发它的那个菜单项传进来）；`ANCHOR_TOP_RIGHT_IN` / `ANCHOR_BOTTOM_RIGHT_IN`：开在 `anchor` **内部**的右上角 / 右下角（按自己宽高内缩，关闭按钮与缩放手柄用的就是这两个）。
  - 位置换算（屏幕坐标 → 挂载点坐标系的 `position`）在 `UIBase.show_at`：**别用 `set_global_position`**（按当前全局变换求逆，重复摆会跟旧 position 复合、越摆越偏），**也别设 `Control.top_level`**（会失去父级可见性继承，宿主关掉后它还留在屏幕上、还能被命中）。
- **菜单链是一棵子树**：`Menu` 挂在宿主下、子菜单挂在"触发它的菜单项"下（`MiniHUD → Menu → Edit → MenuEdit`）。菜单项的功能都作用在宿主上（"关闭"关宿主、"添加关闭按钮"给宿主加 X、"启用拖拽"拖宿主），菜单只是快捷方式——像右键窗口标题栏点"关闭"，关掉的是窗口。宿主一 `hide()`，整条链随之不可见、也不再被指针命中（可见性照常继承）。
  - **菜单项里管理宿主一律写 `host`**（不要数 `@self.parent` 的级数）：链里层级深浅不一（`Menu` 的项 vs `MenuEdit` 的项差着好几层），但 `host` 无论深浅都指向同一个对象；给菜单项再套一层可折叠分组也不会指歪。`self` 留给"我自己的挂载点/锚点"（`UIInteract.open(@self, "MenuEdit", @self)` 用它）。
  - **管理对象不一定是"最顶层那个窗口"**：只认"最近一处声明"——`UIInteract.open(..., host=@self)` 或 `Utils.write("<某UI>.config.host", "UI/MiniHUD/Menu")` 写在谁身上，就以谁为界（它下面的整棵子树都跟它，更近的声明还能再覆盖，所以可以给不同子菜单挂不同的管理对象）。没写 `host` 的链才回退到最外层窗口。**写的是注册名**（字符串：可读、能进 json / 能深拷贝，见 RegSys），所以"哪一层管谁"是可以存盘的配置。
  - - 菜单编辑 ▸ 的"内容对象 ▸"**不写专门面板**：它就是通用 `Editor` + `content_cmd="@host.config.content_cmd"`（编辑单个字符串值 ⇒ 自适应出一个文本框、回车写回并刷宿主）。"对象路径"就是 `content_cmd` 本身，显示 / 编辑都按它取，没有"拿名字再查一次"那层转手。
- **失焦判定也因此变简单**：`UIInteract_OpenClose.close_blur_ui` 判"指针是否在我要的链上"，鼠标在子菜单上时沿 parent 链能走回父菜单，所以父菜单不会被误关。
- **触发**：宿主配置里写 `"events": [[QName.mouseRight, 'UIInteract.open(@self, "Menu", @self, close_on_blur=true)']]`（= `QName.UI_event_mouseRight_menu`）；状态层只需 `Mouse Right → PointerDetect.key "Mouse Right"` 把事件派发给 hover 的 UI，**不需要系统级快捷**。
- **多级菜单 = 菜单开菜单**：菜单项的 `Pointer Enter` → `UIInteract.open self MenuEdit self`（第一个参数是挂载点，第二个是位置锚点，菜单项里都传 `self`），层数不写死。
- **菜单项里的"开关"**（如 `MenuEdit/CloseToggle`）：普通 `UI_Label` 上写两套配置，`"Mouse Left"` 一条串里做三件事——`UIInteract.open(宿主, "CloseButton", 宿主)`（另一套里是 `UIInteract.close(宿主, "CloseButton")`）\v `Utils.swap "@self.config.events" "@self.config.events_2"` \v `Utils.swap "@self.config.content" "@self.config.content_2"` \v `@self.refresh("content")`，于是点第一次开关闭按钮、点第二次关它，文字也跟着换。关闭按钮就是 `Config/UI/UIPreset_Basic.gd` 里的普通预设（`open_at = Enums.OpenAt.ANCHOR_TOP_RIGHT_IN`：开在锚点**内部**右上角，按自己宽度内缩）。
- **关掉 = 隐藏（实例复用）**：关闭统一走 `UIInteract.close`（`hide()` + 广播）；**父 UI 一 hide，挂在它下面的子 UI 随可见性继承一起不可见**，所以不需要"关父菜单时连子菜单一起关"这种递归。`open` 按登记名查——有就"显示 + 重新摆位"，没有才现场创建；同一登记名只有一份，隐藏的实例不参与指针命中、也不算"开着"。
- **隐藏后怎么回来**：`close` 只是 `hide()`，实例还在 `uis` 里，所以重开不用重建——重开统一走 `UIInteract_OpenClose.open`（显示 + 按 `open_at` 摆位，不重建控件；指令形式就是 `UIInteract.open`）。**注意 `PointerDetect` 用 `is_visible_in_tree()` 判命中，隐藏的 UI 再也收不到任何事件**，所以重开的触发不能写在它自己身上（"再点一下"是点不到的），必须来自它仍可见的父级、或系统级的状态/快捷指令。
- **失焦关闭（两套，与"是不是菜单"无关）**：都由 open 登记候选、close 摘掉（只有"开出来的"才可能失焦，配置里的子元素不会单独关；关过再开自动回来）。
  - `close_on_blur`（**点关**）：有按键派发时判一次 ⇒ 指针不在它（或它的子孙元素）上就关。右键菜单用这种——鼠标划过不该把菜单关掉。
  - `close_on_move`（**移开关**）：指针一动就判 ⇒ 不在它（**或它的挂载点**）上就关。hover 展开的子菜单用这种——挪开就收。
    - 为什么要多算一层挂载点：子菜单开在触发项**旁边**（不在触发项的矩形里），指针通常还停在触发项上；只算自己的话，它一开出来就会被自己关掉。
  - **在哪写**：可以写进预设 config，但**推荐开的时候传参**（`close_on_move=true`）——关闭行为只取决于"在哪开、为什么开"，写进预设等于每加一层子菜单都得记得抄一遍，漏一处那个 UI 就永远关不掉。
  - 点关的判定时机：`key()` 派发时只置标记（`PointerDetect._blur_pending`），判定放在**下一次命中刷新**的尾巴上。两个理由：① 判定的那一刻，菜单往往正在被这次派发 open 出来（右键开菜单），拿"上次刷新的 hover"判会把它当成"指针在外面"当场关掉（表现为"关过一次之后就再也开不出来"）；② 命中检测一帧只该有一次（`InputSys._process` 里那次，早于派发），派发完再刷一遍既白跑、又会让 enter/exit 在同帧里派发两次。移开关则挂在 `PointerDetect._process` 的"本帧位移不为 0"分支里（没动就不必重复判）。
  - **尺寸为 0 的先不判**（`get_global_rect()` 是退化矩形 ⇒ 会被误判成"指针在外面"）：布局还没跑时先当它"还在指针下"（多级菜单"一开就没"就是这么来的）。
    - 反过来说：**尺寸被谁压成 0 的 UI 会永远跳过判定 ⇒ 永远关不掉**。踩过这个坑：菜单（free 子元素）被挂进了 `ScrollContainer`（滚动容器会按视口改子节点尺寸），于是它高度 0、菜单既显示不全又关不掉。⇒ 自由定位的子元素必须挂"非容器"的叠加层（`UI_Panel` / `UI_Scroll` 都各有一个 `Overlay`）。

## 长内容与"收回 / 展开"（UIInteract.fold，实现 Interact/UIInteract_Fold.gd）

- **要解决的问题**：一块 UI 的配置太长（菜单项、配置项一大串）时会顶出屏幕下边——子 UI 的"管理菜单"就是这种情况。
- **解法是收起（隐藏）而不是关闭**：`UIInteract.fold(目标, true)` ⇒ 只留**自己标了 `collapse_keep = true`** 的子元素（就是那一行"可折叠标题"），其余子元素 `hide()`；**实例不销毁**，展开回来一切照旧（`close` 是把整个 UI 隐藏，所以不能用来"只收起一段"）。
- **实现只在交互里**（`Script/UI/Interact/UIInteract_Fold.gd`），**`UIBase` 里没有折叠代码**：这事只是"把子元素的 visible 设一下"，不值得让基类为它多记状态、多几个方法。
- **两个配置键，都在元素自己的 config 里**（一份数据一处真相，和别的配置键一个待遇）：
  - 父元素上 `collapsed`：收起态（默认 false = 展开）；
  - **子元素自己**标 `collapse_keep = true`：表示"收起时留着我"（默认不标 = 跟着收起）⇒ "谁留下"写在自己身上，**父元素不用维护名字清单**（子元素改名、加删，都不用回头改父级配置）。
- **为什么收起后就不占屏幕了**：不可见的子元素**不参与容器布局** ⇒ 容器按内容收缩 ⇒ `size` 里为 0 的那一维（"宽固定、高随内容"，菜单/面板都这么配）自己就变短了。
- **一行搞定："可折叠标题"片段**（推荐用法）——`UIInteract_Fold.title_item("标题")` 返回一条普通 `UI_Label` 配置：它自己**既是标题也是收回按键**（显示 `▾ 标题` / `▸ 标题`，点它收起/展开它所在的分组，自带 `collapse_keep: true`）。给一段内容加"收 / 展"就是**加这一行**：
  ```gdscript
  static func title_item(what: String) -> Array:
      return ["Title", "UI_Label", {
          "content": "▾ %s" % what, "content_2": "▸ %s" % what,   # 两套文字对调换箭头（见"开关式按钮"）
          "collapse_keep": true,                                   # 它自己声明"收起时留我"
          "events": [[QName.mouseLeft, 'UIInteract.toggle_fold(@self.parent)'
              + '\vUtils.swap("@self.config.content", "@self.config.content_2")'
              + '\v@self.refresh("content")']],
      }]
  ```
  别的预设直接 `children.append(UIInteract_Fold.title_item("一段很长的配置"))`；想换样子（标题带底、或者另放一个 `[+]` / `[-]` 按钮）照抄这段改 `content` / `events` 即可。
- **从外面调**也一样：`UIInteract.fold(UISys.get_ui("FoldDemo"))` / `unfold(...)`（按键快捷、别的 UI、菜单项都能触发）。想"开出来就是收起的"：在 `open` 那一句后面接一条 `fold`。
- **可以套娃**：外层收起时里面整片一起不可见；外层展开后，里面每一段仍保持它自己收起/展开的状态（状态各自记在各自的 `config` 里）。
- **另一种解法：让面板自己滚**（`UI_Panel` 的 `config["scroll"] = [上限宽, 上限高]`，0 = 该维不限制）：
  收起 / 展开是"我知道哪段可以收"，适合结构固定的菜单；scroll 是"内容长短不定也不怕"，适合
  **同一个界面里值的长度差很多**的场合（UI 编辑器：`size` 就几个字符、`events` 可能几百字）。
  两者能叠：滚动面板里照样放可折叠段（收起后内容变短，面板跟着变矮）。
  实现：面板中间多一层 ScrollContainer（**横向关掉**——长文本自己在框里换行，不用横向拖），
  面板尺寸 = min(内容需要, 上限)（`UI_Panel._content_size`），子元素最小尺寸一变就重算
  （`_box.minimum_size_changed` → `_fit_size`）。
- **注意**：**可折叠标题要标 `collapse_keep: true`**（`title_item` 已经带了），否则收起来就再也没有东西能点开它；收起期间**运行时新加的子元素**不会自动跟着藏（加完再调一次 `fold`）。
- 例子见 `Config/UI/UIPreset_Fold.gd`（`FoldDemo`：整块可收 + 三段各自可收，`Test.ui_test` 里默认开出来）。

## UI 编辑器（元素 Script/UI/UI/UI_Editor.gd + 外壳 Config/UI/UIPreset_Editor.gd）

- **要解决的问题**：一个 UI 的"所有内容"（config 每一项、它的子UI、子UI的子UI…）平时只存在于配置里，
  想现场看看 / 改改只能翻代码。UI 编辑器把这棵树**现场**摆出来，改完立刻生效（不用改配置文件、不用重开 UI）。
- **它就是"编辑器"**：`UI_Editor` 是一个**普通元素**（`extends UI_Panel`），构造时按配置铺出来——
  - `source`：要编辑的那本**字典**在哪（指令取值式路径，如 `"@UI/MiniHUD/Info.config"`；不写 = 用 host 的 config）；
  - `special`：**特别处理的键名**（`{"children": "ui"}` ⇒ 这个键按"子UI"处理）；
  - `kinds`：**某种值用哪个元素渲染**（`{"text": ["UI_Input", {"multiline": true}]}`，默认见 `UI_Editor.DEFAULT_KINDS`）
    ——这是扩展点：想做"数值型 / 文本型 / 列表型编辑器"就是写个新元素再在这里登记一条。
  值的种类自动判：字典 ⇒ 一段 + 递归一个编辑器；子UI数组 ⇒ 每个子UI一段（递归）；
  字符串 / 数字 / 布尔 / 数组 ⇒ 一行（键名 + 输入框，回车提交）。
- **打开就是通用 `open`**（`UIPreset_Menu` 的"UI 编辑器"项）：`UIInteract.open(@host, "Editor", @host, host=@host)`
  ——元素在**登记完成**时自己铺内容（`UIBase.on_registered` 那一声），**没有专用的开启指令**。
- **没有专用交互**（原来的 `UIInteract_Editor` 已删）：展开靠**折叠交互的通用"按需建"**
  （`UIInteract_Fold.fold` 展开时建 `config["items"]`）；改值是两条普通指令
  （`Utils.write` 写值 + `@该UI.reapply()` / `.refresh()` 重应用）；"[重建]"是内容里的第一行
  `@self.parent.rebuild()`（元素自己的方法，整行一条调用）。
- **写回一律走路径**：读到的字典可能是副本（取值式返回的是值），所以写用
  `Utils.write("<source>.<键>", …)`（写回命令见 `UI_Editor` 每行），改的才是本尊。
- **两层分工：外壳走配置、内容走元素**（`Config/UI/UIPreset_Editor.gd`）：
  - **外壳写在 `children` 里**：`Head`（文案由 `editor_rebuild` 写"UI 编辑器：<名字>"）/ `Close` / `Rebuild` / `Body`；
  - **只有 `Body` 是现场铺的**：要铺的东西（有几个子UI、有哪些 config 键）**运行期才知道**，配置里列不全；
    但"行和段长什么样"是**元素**按 `kinds` / `special` 决定的（见 UI_Editor）
    ⇒ **结构在配置、数据在运行期**，两边各管一段。
  - 每次 `editor_rebuild` 只清 `Body` 这一棵子树再重铺（所以头部 / 关闭 / 重建那些固定项不需要打"我是动态的"标记）。
- **每个 UI 都是同样两块**（所以递归下去长得都一样、看的人不用猜）：
  ① 自己的 `Config（N 项）` 段（每项一行：小字键名 + 输入框，回车提交；`children` 不列，它由下面那些段表示）；
  ② 每个子UI一段。
- **子UI默认收起 + 懒铺**：段 = 普通 `UI_Panel` + 一行可折叠标题，内容在**第一次展开时**才铺
  （展开走折叠交互的通用"按需建"，见 `UIInteract_Fold`）——子UI多、层级深时不必一次铺出整棵树；收起后不参与布局、面板自己变短，
  这正是"菜单顶出屏幕"的解药（见上一节）。收起 / 展开本身仍走 `UIInteract.fold`。
- **可折叠标题就是折叠预设那一套**：`UIInteract_Fold.title_item(标题, 收起?)`——
  编辑器与状态一览、快捷一览都用它（段落自己写 `items`，展开时才建），
  箭头对调 / `collapse_keep` / 点完刷新都还在那一处，**没有第二套标题**。
- **编辑哪个 UI 由 `host` 决定**：每段把自己管的那个 UI 写进 `config["host"]` ⇒ 段内所有行都用 `host` 指到它
  （每行的写回命令见 `UI_Editor`），层级再深也不必逐层传参——
  这是 `host` 占位符（"最近声明优先"）最典型的用法：**一段 = 一个"管理对象"的作用域**。
- **值的解析**：文本 → 值走指令解析器那套（`CommandParser.parse_value`：数字 / `true` / `"字符串"` / `[数组]`）；
  **算不出值就按原样字符串**（`res://icon.svg` 这种路径、`MiniHUD/Menu` 这种注册名都不必加引号）；
  空文本 = `null`（清掉这一项）。
- **改完怎么生效**：`reapply()`（`size` / `font_*` / `background` 这些"只有应用时才生效"的）→ `refresh()`
  （content / visible）→ `_fit_size()`（尺寸可能变了）。都不碰 position，除非改的正好是 `position`。
- **不省略任何子UI**：列的就是"这个 UI 实际有的子元素"，一个不漏——多出来的段本来就是折叠的，不占地方
  （想只看自己的值就把不看的段、连顶层那个 Config 段一起收起来）。**"看不见的菜单"列不出来不是省略**：
  没开过的菜单只是个预设、还没有实例，自然也还不是子元素（`open` 过才会出现在 `children` 里）。
- **配置值就用注册名**：`host` 这类键填的就是 `MiniHUD/Menu` 这种名字（`_find_host` 与 `@注册名` 都认），
  写进去就是它——不用对着数字猜"这是谁"，也不怕重开一次就对不上。
- **长度问题两手一起上**：容器 `scroll: [340, 460]`（`UI_Panel` 的滚动，内容再多也只在框内滚）+
  每行的值用**多行输入框**（`UI_Input` 的 `multiline`：自动换行、高度按折行数自适应、`max_height` 封顶）。
- **在编辑器里右键 ⇒ 右键菜单管的是它自己**（`UIEditor` 预设里配了 `QName.UI_event_mouseRight_menu`，
  `self` 就是它）——所以"启用拖拽"拖的是编辑器，不会去动它挂在的那个父 UI。**必须配这条**：
  不配的话右键事件会冒泡到父 UI（编辑器本身不消费），那里配的绑定就把 `host` 解成父 UI 了。
- 想加新的编辑动作（删键、加子UI、改名字…）：往 `UIPreset_Editor` 加配置片段 + 在 `UI_Editor` 里加一条（写回走 `Utils.write`，或元素自己的方法）。

## 按名称绑定（复制名称 / 绑定 ▸）与重名后缀

- **要解决的问题**：一个 UI 把信息交给另一个 UI，而两者谁也不认识谁（不是父子、不在同一预设里）。中间记一个**名字**即可，不需要它们互相持有引用。
- **名字怎么来**：`UIBase._unique_child_name` —— 组装子元素时（配置 `children` 与运行时 `add_child_element` 两条路）都过一遍：
  **同一挂载点下重名就加 `_2`、`_3`…，没重名保持原样**（所以 `Title` 还是 `Title`，不会变成 `Title_1`）。
  判重看"本元素已有的子元素"，不查登记表（建树时父元素自己还没登记）。理由是登记名 = `挂载点登记名/名字` ⇒ 同名就是同一个登记名 ⇒ 互相覆盖。
- **流程**：右键目标 → "复制名称"（`Utils.copy(@host.config.reg_name)`，复制的是**登记名**，如 `UI/TestShow`、`UI/MiniHUD/Title`，带后缀的真名）
  → 右键要收信息的 UI → 用编辑器把它那一行改成那条路径（写进 `content_cmd`）→ 之后发信息就走这条路径。
- **对象路径直接写在 `content_cmd` 上**（`"host.config"` 这种相对写法也行）：不再有"沿 parent 找 bind 名"这一层转手。
- 例子见 `Config/UI/UIPreset_Test.gd`（`TestShow` 显示 / `TestInput` 输入，J / K 键开关）。

## 键盘快捷键界面（Config/UI/UIPreset_Keyboard.gd）

- **一份配置搞定**：`values` 里只有一个 `Keyboard`（`UI_Panel`），103 个键的子元素由文件里的 `KEYS` 表**在 values 外算好**再由 values 引用（`_layout`）。
- `KEYS` 每列是 **[键码, x, 行, 尺寸, 显示文本]**（左右修饰键多一列 `KEY_LOCATION_LEFT/RIGHT`）：表中数值照抄 Unity 那版的原表达式（`32*2`、`row1 = -36*2`…），统一再乘一个 `SCALE`（表里数值保持与 Unity 一致，**要缩放只改 `SCALE`**）。`SCALE = 1.0` 就是与 Unity 同尺寸（面板 1600×576、键 64×64），比默认窗口 1152×648 大；想缩进小窗口就调小它（如 0.7 ⇒ 1120×403）。字号不跟着 `SCALE` 走，改完要自己看着调。
- **键码才是"这个键是谁"**（`KEY_ESCAPE` / `KEY_Q` / `KEY_KP_8`…），最后一列只是给人看的文本（"Esc"、"Space"）。以后"点某个键 → 把它绑到某操作"就是拿 `config["key_code"]`（+ `key_location`）造 `InputEventKey`。
  - 左右修饰键在 Godot 里 keycode 相同（Shift/Ctrl/Alt 各一对），靠 `InputEventKey.location` 区分 → 表里多一列位置，**元素名也随之带 `_L`/`_R`**（不带的话两个键会注册到同一个名字下互相覆盖）。
  - 元素名由键码字符串生成：`Escape→Key_Escape`、`Kp 8→Key_Kp8`、`Slash→Key_Slash`、`Shift+LEFT→Key_Shift_L`（生成时做重名检查并警告）。
- 每个键 = 一个 `free` 的 `UI_Panel`（绝对坐标定位，底图 `KEY_BG`，配置里带 `key_code` / `key_location`）+ 两个 `UI_Label`：`Name` 键名（Esc / Q …）、`Desc` 当前绑定的操作。**字号与字色都配在这两个文本上**（`font_size` / `font_color`）——不配字色就是主题默认的近白色，画在浅色键底上会看不见。
- **整块面板可拖动**：按住 → `UIInteract.drag self event` 登记 → 每帧 `dragging`（子元素没配这个事件时会冒泡到这里，与 MiniHUD 标题栏同一套）。
- **底图**走 `UI_Panel.background`（九宫格），面板与键共用 `Material/Texture/UI/RoundedIcon_32.png`；图片缺失只警告一次、改用默认面板样式，不影响运行。
- **以后给键绑操作**：改它的描述文本即可，登记名 = `Keyboard/键名/Desc`（键名由键码生成，如 `Keyboard/Key_Q/Desc`、`Keyboard/Key_Kp8/Desc`、`Keyboard/Key_Shift_L/Desc`）。
- **开启**：独立 UI，`UIInteract.open(preset_name="Keyboard")`；右上角的 "X" 就是普通预设 `CloseButton`（`UIInteract.open(键盘, "CloseButton", 键盘)`）——见 `Test.ui_test`。

## 消息（MessageHub.gd）
- `send_ui_create/remove(ui)` 与 `listen_ui_create/remove`。
- `send_ui_press/drag/release/submit/close/scale(ui)`、`send_ui_fade(ui, target)` 与对应 `listen_ui_*`：每个函数固定 action，id 为 `format_ID(["UI", 该 UI 的注册名, action])`（见 `Msg._format_ui`）。
- 现在这些消息主要作为**未配指令元素**的默认出口；配了指令的元素改走 `Msg.send_cmd`。

## 已确认但暂缓 / 留空
- `PointerDetect` 已提供 `hover_char` / `map_position`，角色/地图的交互派发暂缓；`track_id`（UI 跟随角色）随开关一起移除，待需要时以指令形式回归（如 `UIInteract.follow @self.parent @角色ID`）。
- 多套 UI 版本（横竖屏/字体缩放）、可视化编辑器、缩放指令（`UIInteract.scale`）。
- 更细的 style 默认值回退链（元素→父→UI 根→全局默认）后续按需补。
