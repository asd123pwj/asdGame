# UI · UI 界面系统

## 定位
UI 系统遵循项目统一范式（见 `设计文档.md` §二/§三/§十）：**UIPreset**（配置）→ **UiSys**（管理脚本，文件 `UiSystem.gd`）→ **UIBase**（元素基类）→ `Config/UI/` 配置类。
- `UIBase extends BaseClass`，**不直接继承 Control**：内部用变量持有 `control: Control`（真正的引擎节点），不用自定义 signal。
- **一个 UI = 多个基本元素的组装**：根元素（如 `UI_Panel`）由 config["children"] 声明子元素（都是 UIBase 子类），build 时递归组装。
- **交互 = 指令**：元素不再用 `draggable/closeable/...` 开关，而是"事件→指令"——`config["events"]` 是 `[事件名, 指令串]` 的列表，事件发生即发送对应指令；**事件名就是状态名**（如 `"Mouse Left"`、`"Mouse Left | Tick"`，UI 不感知键位，键位只在状态层配），hover 变化用 `PointerDetect.EVENT_POINTER_ENTER` / `EVENT_POINTER_EXIT`；指令里 `$parent`(挂载对象)/`$self`(自身) 在发送前替换为实例（`$@ID` 形式）。想要什么行为就配什么指令（拖动手柄配 drag 指令、关闭按钮配 close 指令）。
- **显示内容统一挂 `content` 属性**：元素展示什么由 content 决定，改内容 = `set_content(v)`（内部自动 `refresh()`），不必重建控件。

## 目录与命名约定
```
Script/UI/
├─ UI.md                 # 本文档
├─ UIPreset.gd           # UI 预设（extends PresetRegister）：一条 UI 配置 + create_element 工厂
├─ UiSystem.gd           # UI 系统（class_name UiSys，extends BaseClass）：开启/登记 UI 树（成员全静态）
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
| `UiSystem.gd` | UI 系统 `UiSys`：开启/登记**整棵 UI 树**（子元素一并登记），成员全静态，日常直接 `UiSys.xxx`。 |
| `UIInteract.gd` | **交互指令宿主**（静态方法自动注册为指令）：`UIInteract.open_ui/close/close_ui/drag/fade_to/set_content/swap_config/enable_drag`；`open_ui` 只转发给 `UiSys.open_ui`。 |
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

## UiSystem.gd（class_name UiSys，extends BaseClass）
- **成员全是静态的**：`static var root: CanvasLayer` 与 `static var uis: Dictionary[String, UIBase]`，调用直接写 `UiSys.open_ui(...)` / `UiSys.uis` / `UiSys.root`，不用经 `Sys.uiSys`（那个实例只用于启动时跑一次 `_init` 建 UI 根）。
- **挂载规则**（决定 UI 树 ⇒ 决定"关谁连谁一起关"和 `$parent` 的级数）：有 `anchor`（触发它的那个元素）→ **挂在 anchor 下**；没有 anchor → 挂在 `host` 下；都没有 → 挂 UI 根（独立 UI）。所以"菜单开子菜单"得到的是一棵**单链子树**：`MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`。
- **登记名规则**（唯一的"寻址"约定，`_reg_name`，**只有这一条**）：没有挂载点 → 就是预设名（`MiniHUD`）；有挂载点 → `挂载点的登记名/名字`（`MiniHUD/Menu`、`MiniHUD/Menu/Edit/MenuEdit`）。**"开出来的 UI"与"配置里的子元素"共用它**（子 UI 的名字就是它的预设名），所以登记表是一整棵 `/` 连接的树；**"是否能复用"就是一次 `uis.get(登记名)`**，不需要按类型遍历。同一挂载点下不要重名。
- `open_ui(preset_name, host := null, anchor := null)`：**全项目唯一的开启入口**（普通 UI 与菜单同一条路，不要再写第二个）。
  - `host` 为空 → 独立 UI：建预设自己那份 → 挂 `root` → 登记（登记名就是预设名，如 `MiniHUD`）→ `Msg.send_ui_create`。
  - 给了 `anchor` / `host` → 深拷贝模板 → `挂载点.add_child_element` 挂到它下面 → **登记名 = `挂载点登记名/预设名`**（如 `MiniHUD/Menu`、`MiniHUD/Menu/Edit/MenuEdit`）；两者都不给则挂 UI 根、登记名就是预设名。
  - 已存在就**只显示 + 重新摆位**，不重建控件——"是否存在"就是一次字典查找 `uis.get(登记名)`（命名规则见 `UiSys` 文件头），**没有任何按 UI 类型的特判**。
  - 子元素进 `uis` 是为了 **PointerDetect 能把指针命中派发到具体子元素**（如关闭按钮、菜单项）；`uis.values()` 后加入者靠前，倒序命中即"子元素优先于父"。
- `get_ui(name)`：按登记名取（子元素用全名，如 `MiniHUD/Info`）。
- `register_child(parent, child)` / `find_name(ui)`：登记与反查（`UIBase.add_child_element` → `register_child`），都用 `_reg_name` 那一条规则（`挂载点名/名字`）——所以开出来的 UI 与配置子元素同名规则，`open_ui` 的复用查找（`get_child_ui`）才命得中。
- `get_child_ui(mount, preset_name)`：按"挂载点 + 预设名"取已登记的 UI（= `open_ui` 复用时那把钥匙的公开形式）——`UIInteract.close_ui` 就是靠它"关掉挂在某宿主下的某预设"。
- **"给某个 UI 加/减东西"= 开/关一个预设 UI**：不再有 `add_close_button` / `remove_close_button` 这类成对的专门函数（那正是"同一需求两套策略"）。关闭按钮就是一个普通预设 `CloseButton`（`Config/UI/UIPreset_Basic.gd`，`open_at = ANCHOR_TOP_RIGHT_IN` 开在锚点内部右上角），加它 = `open_ui <宿主> CloseButton <宿主>`，减它 = `close_ui <宿主> CloseButton`。
- **只管生命周期，交互实现都在 `UIInteract`**。

## UIBase.gd（extends BaseClass）
- `var control: Control`；`build()` = `_create_control()` → `_apply_config()` → `refresh()` → `_build_children()`。
- **`var content: Variant`**：显示内容（子类解释：Label=文本、Scroll=多行文本、Image=纹理路径）。`set_content(v)` 改内容并自动 `refresh()`；子类覆写 `refresh()` 把 content 刷到控件。
- **`var parent: UIBase`**（挂载对象）：组装子元素时由父元素注入，是 `$parent` 的指向。
- **`var children: Array[UIBase]`**：按 `config["children"]`（每项 `[child_name, ui_class, child_config]`）组装，挂到 `_content_box()`（容器类覆写返回内部布局节点）。
- **事件→指令**：唯一入口 `on_event(事件名)`（由 PointerDetect 派发）：
  - 事件名就是**状态名**（如 `"Mouse Left"`、`"Mouse Left | Tick"`）——**UI 不感知按键**，键位只在状态层 `statuses` 的 `keys` 里配置；hover 变化不对应状态，用 `PointerDetect.EVENT_POINTER_ENTER / EVENT_POINTER_EXIT`。
  - 在 `config["events"]`（`[事件名, 指令串]` 列表）里**按等值**取指令串 → `Msg.send_cmd(UIInteract.resolve_cmd(指令串, self))`（解析 `$parent`/`$self` 占位符）。
  - 用列表而非字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），加新事件只需加一项。
  - 自己没配的事件**冒泡给父级**，冒泡到根都没有才什么都不做（元素没有隐式行为）；于是"整块面板的行为"在子元素上同样生效（如菜单面板启用拖拽后，按住菜单项也能拖），`$self/$parent` 以"配了指令的那个元素"为基准。
- **运行时增改**：`add_child_element(name, ui_class, config, reg_name := "")` 加子元素（内部交给 `UiSys.register_child` 登记，登记后才可被指针命中；`reg_name` 由开 UI 的路径显式指定，普通子元素留空）；`add_event(事件名, 指令串)` 追加事件绑定；`swap_config(键A, 键B)` 对调两项配置（开关式按钮的底座）——菜单的"启用拖拽"（`enable_drag`）就是这一条；而"关闭按钮"连新指令都不需要：它是普通预设 `CloseButton`，用 `open_ui` / `close_ui` 开关。
- **开关式按钮（可选框）**：不需要专门元素——同一个元素上放两套配置（`events` / `content` 与 `events_2` / `content_2`），点击时"做事 + `swap_config` 对调"，下次点击自然走另一套。事件串里多条命令用 `\v` 分隔（见 `CmdSys.execute`）。
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
    - 九宫格边距默认 `BG_SLICE`（8，按 32px 圆角方块定的）；不同图的圆角不一样，可用 `background_slice` 逐元素指定。
  - `size` 里为 **0 的那一维按"内容最小尺寸"补足**（`_fit_size()`；"内容要多大"由可覆写的 `_content_size()` 给出）：`[150, 0]` = 宽固定、高随内容；`[0, 0]` = 完全由内容决定。**必须补**——控件尺寸为 0 时 `get_global_rect()` 是退化矩形，PointerDetect 永远命中不到它（菜单"一打开就没了"就是这么来的：矩形高度 0 → 失焦判定以为指针在菜单外 → 同一帧里就把它关了）。
  - **`UI_Panel` 的 `_content_size()` 必须问内部的 `PanelContainer`，不能问根控件**：根是普通 `Control`，**不会汇总子元素的最小尺寸**，问它只会得到 `custom_minimum_size`（`[150, 0]` → 高度就是 0）。而且建时还没进树、字体主题都问不出来，所以要挂在 `_panel.minimum_size_changed` 上再补一次。
  - 指令串参数：**只有中间带空格时才需要引号**（如 `"Mouse Left | Tick"`），其余直接写名字（如 `open_menu $self Menu`）。
  - **自由定位元素不要设 `Control.top_level`**：那会让它不再继承父级可见性（宿主 `hide()` 后它还留在屏幕上、也还能被命中）。摆放时把屏幕坐标换算成**宿主坐标系的 `position`**（挂载点原点即宿主原点）；也不要用 `set_global_position`——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏。
- **只存"何时发什么指令"**：无 `close()/fade_to()` 等交互实现（都在 `UIInteract`），无 `draggable/closeable/...` 开关。

## 交互指令（Script/UI/UIInteract.gd，静态方法 → 指令）
- **这些都是纯副作用指令（`-> void`）**：只做 close/hide、改 position、起 Tween、转发消息，不返回值。因此被指令系统调用时不会在 `send_cmd` 的结果数组里多套一层，无需 `[0]` 剥离。
- **参数类型 `target: UIBase`**：指令里的 `$parent/$self` 由 `resolve_cmd` 转成 `$@ID`，指令系统执行 `$` 表达式时用 `instance_from_id` 取出**实例**再传入，所以这里收到的必然是 UIBase，不是 ID 也不是名字。
- **`_as_ui(target, cmd_name)`**：只做校验、不再做"名字→实例"归一化（该路径已由指令系统承担）。target 为空、或目标尚未 `build()`（`control == null`）时 **`push_warning` 指明是哪个指令**，而不是静默 return——避免配置/组装写错却无提示。
- **`resolve_cmd(cmd, sender)`**：解析占位符——`$self`→自身；`$parent`→父 UI，`$parent.parent`→祖父（链式任意级，`_climb_parent` 实现；**级别不足时 `push_warning` 并用可达的最高级替代**）；链尾 `.xxx` 原样保留（`$parent.parent.text` → `$@ID.parent…` 后由指令系统继续按表达式取属性）。
| 指令 | 作用 | 典型配置 |
|---|---|---|
| `UIInteract.close $parent` | 关闭（隐藏）目标 UI（发 `Msg.send_ui_close` + hide） | 关闭"按钮"的 press |
| `UIInteract.open_ui [宿主] 预设名 [锚点]` | 开启/重开一个 UI（显示 + 按 `open_at` 摆位；不重建控件）。**锚点同时是挂载点**（子菜单挂到触发它的菜单项下）；宿主与锚点都省略 = 独立 UI | 面板右键开菜单、多级菜单、外部唤出 |
| `UIInteract.drag $parent` | 把指针**本帧累计位移**（`InputSys.mouse_delta`）作用到目标 UI | 拖动手柄的逐帧状态（如 `"Mouse Left | Tick"`） |
| `UIInteract.fade_to $parent 0.0 0.5` | 透明度渐隐/渐显（alpha, duration；**指令调用须写全参数**） | 提示淡出 |
| `UIInteract.set_content $parent "文本"` | 修改显示内容（→ refresh） | 更新滚动区文本 |
| `UIInteract.swap_config $parent 键A 键B` | 对调目标 `config` 里两项的值（如 `events`↔`events_2`、`content`↔`content_2`），换完同步镜像（content/visible）并 refresh——**开关式按钮就靠它 + 多命令实现** | 可选框/开关按钮的 `"Mouse Left"` |
| `UIInteract.close_ui $parent 预设名` | 关闭（隐藏）**挂在 target 下的某个预设 UI**（按"挂载点 + 预设名"查，没开过就什么都不做）。与 `open_ui` 成对：给某个 UI 加/减东西 = 开/关一个预设 | 开关式按钮的"移除"一侧：`close_ui <宿主> CloseButton` |

## 原子元素（Script/UI/UI/）
| 类 | 职责 | 事件配置示例 |
|---|---|---|
| `UI_Panel` | 面板容器：PanelContainer+Margin+VBox，子元素竖排；自身无功能逻辑。`background` 可给整块面板铺一张九宫格底图 | — |
| `UI_Label` | 文本：content 即文本；**配 `"Mouse Left"` 即"按钮"、配 `"Mouse Left | Tick"` 即"拖动手柄"**（无需单独 Button 类） | `["Mouse Left", "UIInteract.close $parent"]` |
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
                "events": [["Mouse Left | Tick", "UIInteract.drag $parent"]],
            }],
            # "按钮" = 文本元素 + "Mouse Left" 指令，无需 Button 子类
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [["Mouse Left", "UIInteract.close $parent"]],
            }],
            ["Info", "UI_Scroll", { "content": "初始内容" }],
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
]
```
- 组装读法：根 `UI_Panel` 含三个子元素——标题栏按住拖动父 UI、文本"按钮"关闭父 UI、滚动区展示内容；改展示内容只需 `get_ui("MiniHUD/Info").set_content(...)` 或发 `UIInteract.set_content` 指令。

## 右键菜单（Config/UI/UIPreset_Menu.gd 的配置 + 通用 UI 机制）
- **菜单没有专属类**：就是普通 `UI_Panel` + 三条配置（`open_at` / `close_on_blur` / `free`）——`UiSys` 读配置统一处理"开在哪"和"失焦关闭"，所以"换一套配置"就等于换一种菜单。菜单项就是它 `config["children"]` 里的普通子 UI，行为由子 UI 的事件绑定给出。
- **开启 = 开一个 UI（唯一入口 `UiSys.open_ui`）**：`UIInteract.open_ui` 只是指令入口，原样转发过去（指令里的 `$self`/`$parent` 要先由 `resolve_cmd` 换成实例，所以保留这个壳，它不含任何策略）。**挂哪由 anchor/host 决定**（见上面的挂载规则），摆在哪由**被开启 UI 自己配置里的 `open_at`** 声明：
  - `host` 为空 → 独立 UI 挂 UI 根，指令写成 `UIInteract.open_ui --preset_name MiniHUD`（命名参数跳过 target）。
  - 有 `anchor`（多级菜单：触发它的那个菜单项）→ **挂在 anchor 下**，子菜单成为该菜单项的后代；只给 `host` → 挂在 host 下。
  - `Enums.OpenAt.CONFIG`（不写 `open_at` 时的默认）：摆回配置里的 `position`；`POINTER`：开在指针处（右键菜单——**仍然要传 anchor**，因为它决定挂在谁下面）；`ANCHOR_TOP_RIGHT`：开在 `anchor` 的右上角顶点（多级菜单把触发它的那个菜单项传进来）。
  - 位置换算（屏幕坐标 → 挂载点坐标系的 `position`）在 `UIBase.show_at`：**别用 `set_global_position`**（按当前全局变换求逆，重复摆会跟旧 position 复合、越摆越偏），**也别设 `Control.top_level`**（会失去父级可见性继承，宿主关掉后它还留在屏幕上、还能被命中）。
- **菜单链是一棵子树**：`Menu` 挂在宿主下、子菜单挂在"触发它的菜单项"下（`MiniHUD → Menu → Edit → MenuEdit`），所以菜单项里 `$parent` = 菜单本身，往上级数就是往上级 UI：`Menu` 的项用 2 级 = 宿主，`MenuEdit` 的项用 4 级 = 宿主（**链每深一层，到宿主多一级**）。菜单项的功能都作用在宿主上（"关闭"关宿主、"添加关闭按钮"给宿主加 X、"启用拖拽"拖宿主），菜单只是快捷方式——像右键窗口标题栏点"关闭"，关掉的是窗口。宿主一 `hide()`，整条链随之不可见、也不再被指针命中（可见性照常继承）。
- **失焦判定也因此变简单**：`UiSys.close_blur_ui` 判"指针是否在我要的链上"，鼠标在子菜单上时沿 parent 链能走回父菜单，所以父菜单不会被误关。
- **触发**：宿主配置里写 `"events": [["Mouse Right", "UIInteract.open_ui $self Menu $self"]]`；状态层只需 `Mouse Right → PointerDetect.key "Mouse Right"` 把事件派发给 hover 的 UI，**不需要系统级快捷**。
- **多级菜单 = 菜单开菜单**：菜单项的 `Pointer Enter` → `UIInteract.open_ui $self MenuEdit $self`（第一个参数是挂载点，第二个是位置锚点，菜单项里都传 `$self`），层数不写死。
- **菜单项里的"开关"**（如 `MenuEdit/CloseToggle`）：普通 `UI_Label` 上写两套配置，`"Mouse Left"` 一条串里做三件事——`open_ui <宿主> CloseButton <宿主>`（另一套里是 `close_ui <宿主> CloseButton`）\v `swap_config $self events events_2` \v `swap_config $self content content_2`，于是点第一次开关闭按钮、点第二次关它，文字也跟着换。关闭按钮就是 `Config/UI/UIPreset_Basic.gd` 里的普通预设（`open_at = Enums.OpenAt.ANCHOR_TOP_RIGHT_IN`：开在锚点**内部**右上角，按自己宽度内缩）。
- **关掉 = 隐藏（实例复用）**：关闭统一走 `UIInteract.close`（`hide()` + 广播）；**父 UI 一 hide，挂在它下面的子 UI 随可见性继承一起不可见**，所以不需要"关父菜单时连子菜单一起关"这种递归。`open_ui` 按登记名查——有就"显示 + 重新摆位"，没有才现场创建；同一登记名只有一份，隐藏的实例不参与指针命中、也不算"开着"。
- **隐藏后怎么回来**：`close` 只是 `hide()`，实例还在 `uis` 里，所以重开不用重建——重开统一走 `UiSys.open_ui`（显示 + 按 `open_at` 摆位，不重建控件；指令形式就是 `UIInteract.open_ui`）。**注意 `PointerDetect` 用 `is_visible_in_tree()` 判命中，隐藏的 UI 再也收不到任何事件**，所以重开的触发不能写在它自己身上（"再点一下"是点不到的），必须来自它仍可见的父级、或系统级的状态/快捷指令。
- **失焦关闭（纯配置驱动）**：谁写了 `close_on_blur = true` 谁就有这个行为（与"是不是菜单"无关）。`PointerDetect.key` 派发完按键事件后：`UiSys.has_blur_ui()` → 先 `update_targets()` 刷新命中（这类 UI 常是刚在指针处打开的，用旧 hover 会误判成"外面"）→ `UiSys.close_blur_ui(hover_ui)`：遍历登记表，指针不在该 UI（或它的子孙元素）上就 `UIInteract.close` 关掉。

## 键盘快捷键界面（Config/UI/UIPreset_Keyboard.gd）

- **一份配置搞定**：`values` 里只有一个 `Keyboard`（`UI_Panel`），103 个键的子元素由文件里的 `KEYS` 表**在 values 外算好**再由 values 引用（`_layout`）。
- `KEYS` 每列是 **[键码, x, 行, 尺寸, 显示文本]**（左右修饰键多一列 `KEY_LOCATION_LEFT/RIGHT`）：表中数值照抄 Unity 那版的原表达式（`32*2`、`row1 = -36*2`…），统一再乘一个 `SCALE`（表里数值保持与 Unity 一致，**要缩放只改 `SCALE`**）。`SCALE = 1.0` 就是与 Unity 同尺寸（面板 1600×576、键 64×64），比默认窗口 1152×648 大；想缩进小窗口就调小它（如 0.7 ⇒ 1120×403）。字号不跟着 `SCALE` 走，改完要自己看着调。
- **键码才是"这个键是谁"**（`KEY_ESCAPE` / `KEY_Q` / `KEY_KP_8`…），最后一列只是给人看的文本（"Esc"、"Space"）。以后"点某个键 → 把它绑到某操作"就是拿 `config["key_code"]`（+ `key_location`）造 `InputEventKey`。
  - 左右修饰键在 Godot 里 keycode 相同（Shift/Ctrl/Alt 各一对），靠 `InputEventKey.location` 区分 → 表里多一列位置，**元素名也随之带 `_L`/`_R`**（不带的话两个键会注册到同一个名字下互相覆盖）。
  - 元素名由键码字符串生成：`Escape→Key_Escape`、`Kp 8→Key_Kp8`、`Slash→Key_Slash`、`Shift+LEFT→Key_Shift_L`（生成时做重名检查并警告）。
- 每个键 = 一个 `free` 的 `UI_Panel`（绝对坐标定位，底图 `KEY_BG`，配置里带 `key_code` / `key_location`）+ 两个 `UI_Label`：`Name` 键名（Esc / Q …）、`Desc` 当前绑定的操作。**字号与字色都配在这两个文本上**（`font_size` / `font_color`）——不配字色就是主题默认的近白色，画在浅色键底上会看不见。
- **整块面板可拖动**：`"Mouse Left | Tick"` → `drag $self`（子元素没配这个事件时会冒泡到这里，与 MiniHUD 标题栏同一套）。
- **底图**走 `UI_Panel.background`（九宫格），面板与键共用 `Material/Texture/UI/RoundedIcon_32.png`；图片缺失只警告一次、改用默认面板样式，不影响运行。
- **以后给键绑操作**：改它的描述文本即可，登记名 = `Keyboard/键名/Desc`（键名由键码生成，如 `Keyboard/Key_Q/Desc`、`Keyboard/Key_Kp8/Desc`、`Keyboard/Key_Shift_L/Desc`）。
- **开启**：独立 UI，`UIInteract.open_ui --preset_name Keyboard`；右上角的 "X" 就是普通预设 `CloseButton`（`open_ui <键盘> CloseButton <键盘>`）——见 `Test.ui_test`。

## 消息（MessageHub.gd）
- `send_ui_create/remove(ui)` 与 `listen_ui_create/remove`。
- `send_ui_press/drag/release/submit/close/scale(ui)`、`send_ui_fade(ui, target)` 与对应 `listen_ui_*`：每个函数固定 action，id 为 `format_ID(["UI", str(ui.ID), action])`。
- 现在这些消息主要作为**未配指令元素**的默认出口；配了指令的元素改走 `Msg.send_cmd`。

## 已确认但暂缓 / 留空
- `PointerDetect` 已提供 `hover_char` / `map_position`，角色/地图的交互派发暂缓；`track_id`（UI 跟随角色）随开关一起移除，待需要时以指令形式回归（如 `UIInteract.follow $parent $@角色ID`）。
- 多套 UI 版本（横竖屏/字体缩放）、可视化编辑器、缩放指令（`UIInteract.scale`）。
- 更细的 style 默认值回退链（元素→父→UI 根→全局默认）后续按需补。
