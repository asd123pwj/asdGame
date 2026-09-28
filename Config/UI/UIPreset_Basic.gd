class_name UIPreset_Basic
extends ConfigBase

"""
name: String
ui_name: String
config: Dictionary

交互不是开关，而是"事件→指令"：config["events"] 是 [事件名, 指令串] 的列表，事件发生即发指令。
事件名就是状态名（见 Archetype_System 的 statuses，如 "Pointer 1 Hold"）——UI 不关心键位，
键位只在状态层配置；hover 变化用 QName.pointer_enter / QName.pointer_exit。
占位符只有 self（自身）、host（本条链的**管理对象**）与 event（事件名）；
取父级/内容一律在它上面接着写取值链：
  @self.parent = 挂载对象（父 UI），self.config.content = 自己的显示内容，
  host = 管理对象（默认沿 parent 爬到顶那个 UI；也可以在某一层 config["host"] 写**注册名**指定成别的 UI，
         或 open 时给 host=@self）——菜单项/深层子元素用它，不必数 @self.parent 的级数。
交互指令宿主为 UIInteract（close/open/toggle/drag/rescale/fade_to/begin_edit/end_edit/switch_value/set_top）；
"写内容 / 对调配置"不需要专门交互：通用指令 Utils.write / Utils.swap + 一条刷新（详见 Script/UI/UI.md）。

原子元素（显示/交互有明显差异的才做子类）：
  UI_Panel  面板容器（竖排布局，用于堆叠子元素；内容装不下就在框内滚动）
  UI_Label  文本（兼作"按钮"：配置 press 指令即可，无需单独 Button 类）
  UI_Image  图片（content = 纹理路径；改图 = 写 config["content"] + refresh("content")）
"**会滚的多行文本**"不再有专门元素：一个 `UI_Panel` + 下面 `text_item()` 的正文子元素就是它。
组合按钮 = Panel(背景) + Label(文字) 直接用配置堆叠，不写子类。
开关式按钮（可选框）也不用专门元素：同一个元素上写两套配置（events/content 与 events_2/content_2），
点击时用 Utils.swap 对调、再 @self.refresh("content") 即可——见 Config/UI/UIPreset_Menu.gd 的 CloseToggle。

预设也是"普通 UI"，所以重复出现的东西（关闭按钮 CloseButton、缩放手柄 ResizeButton、改尺寸手柄 SizeGrip）
都做成预设、用 UIInteract.open / close 开与关，不写专门函数。**悬停说明**（这几个按钮"移上去说一句"）用下面的
"Tip" 预设 + `tip_events(文字)`：内容由开它的那一句带进去，所以一份预设够全项目用。
**这三个按钮都挂在宿主窗口"右侧外面"的一列里**（`open_at = ANCHOR_RIGHT_OUT`，见 Enums.OpenAt 与
`UI_Panel._corner_box`）：**列左沿 = 窗口右边缘、列上沿 = 窗口上边缘**，往下一个一个排 ⇒ 按钮不占窗口内容的
地方，窗口再小也摆得下（画在窗口外照样能点：命中判定不做祖先矩形剪枝）。**列内顺序 = 添加顺序**
（先开的在上面：窗口自带的关闭按钮最先加 ⇒ 永远在最上；两个手柄谁先开谁在上面）。

要"**定死可视区、内容多了在里面滚**"就把面板的 `size` 两维都写数（那是要不要出滚动条的判据）；
写 0 / 不写的那一维随内容走，长到刚好装下、不出滚动条。
"""
## 图标（**换图只改这几行**）＝一套竹框图标，都是 **64×64**、四角各 16×16、最外 4px 透明
## （和窗口那张竹框同一套画法，所以贴上去边框能接上）。
## **一律按原图 1:1 显示**（`ICON_SIZE`）：缩小（如 32）会让像素对不上——0.5 缩放 = 丢一半像素，
## 最近邻也救不回。换图时按新图的原始边长改 `ICON_SIZE`。
const CLOSE_ICON := "res://Material/Texture/UI/UI_Bamboo_CloseButtom.png"       # 关闭（外置列，最上）
const RESCALE_ICON := "res://Material/Texture/UI/UI_Bamboo_RescaleButtom.png"   # 等比缩放
const RESIZE_ICON := "res://Material/Texture/UI/UI_Bamboo_ResizeButtom.png"     # 改尺寸
const ICON_SIZE := 64
## 同族的 `UI_Bamboo_CheckBox_Checked.png`（可选框打勾）**还没用上**：项目里现无可选框元素
## （`UI_CheckBox` 只剩一个空 .uid 残留），做那个元素时直接把它当 `content` 接进来即可。


## 右上角那个**图标式关闭按钮的配置**——只写一份，两个用法：
##   · 当 `children` 里的一项：`UIPreset_Basic.close_item(),`（窗口自带，如一览 / 编辑器 / MiniHUD）
##   · 当独立预设：`UIInteract.open(宿主, "CloseButton", 宿主)`（运行时加/减，如键盘 UI）
## 图 = `CLOSE_ICON`（`UI_Image` 的 content 即纹理），`free` + `open_at = ANCHOR_RIGHT_OUT`
## ⇒ 挂进**本窗口右侧外面那一列**（列首、最上面那个；落点见 UI_Panel._corner_box——整列由锚点维护，
## 窗口宽高随内容变也跟得上），点它关掉所在的窗口（`@host`，见 QName.UI_event_pointer1_close_host）。
static func close_cfg() -> Dictionary:
    return {
        "content": CLOSE_ICON,
        "size": [ICON_SIZE, ICON_SIZE],                # 1:1 不缩放（见上面图标那段的说明）
        "free": true,                                  # 自由定位：挂到窗口叠加层，位置不被竖排布局改
        "open_at": Enums.OpenAt.ANCHOR_RIGHT_OUT,      # 挂在窗口右侧外面的那一列里（列首）
        "events": [QName.UI_event_pointer1_close_host] + tip_events("关闭"),
    }


## 把 `close_cfg()` 包成"`children` 里的一项"（`[名字, 类, 配置]`，见 UIBase._build_children）。
## 元素名**必须与 CloseButton 预设同名**：`UIInteract.open / close` 按"挂载点 + 预设名"寻址
## （见 UIInteract_OpenClose._child_ui），名字对不上时菜单的"启用/移除关闭按钮"开关就会
## 找不到窗口自带的这个、又建一个（实测：叫 "Close" 时看板出现两个 X）。
static func close_item() -> Array:
    return ["CloseButton", "UI_Image", close_cfg()]


## "悬停弹说明"那两条事件：指针移上去开、移开收，开的就是下面的 "Tip" 预设（内容由这里给）。
## **给按钮这种"整块都算说明"的元素**用；文本里的链接不用它——那种走链接的 meta
## （见 UIInteract_Meta），因为"这一行里哪几个字有说明"只有链接自己知道。
static func tip_events(text_: String) -> Array:
    return [
        [QName.pointer_move, 'UIInteract.open(@self, "Tip", @self, content="%s")' % text_],
        [QName.pointer_exit, 'UIInteract.close(@self, "Tip")'],
    ]


## 那两个手柄的配置——**只有图标、"按住后登记哪个交互"和说明文字不同，其余一样**，所以合一：
##   · `QName.UI_event_pointer1_rescale_host`：等比缩放（整块放大，字也变大）= "看得更大"；
##   · `QName.UI_event_pointer1_resize_host`：改宽高（内容照新宽度折行）= "看更多字"。
## 两个都挂进**宿主窗口右侧外面那一列**（`ANCHOR_RIGHT_OUT`）——和关闭按钮同一列，往下一个一个排。
## **挂在哪与"拖的是谁"无关**：hold 起来登记的是 `@host`（那个窗口），所以列挂在窗口外侧，
## 拖动/缩放照样作用在窗口上；元素在哪一格只影响"看着在哪"。
## 元素侧只有"按住"这一条：登记后由 AutoSys 每帧调（松开时状态不满足，AutoSys 自己删登记 ⇒
## 不用写"松开"，也不存任何跨帧状态）。用 Hold 不用 Press：它只在"开始按住"那一下触发。
static func handle_cfg(icon: String, hold_bind: Array, tip: String) -> Dictionary:
    return {
        "content": icon,                               # 两个手柄各用各的图（见上面那三个常量）
        "size": [ICON_SIZE, ICON_SIZE],                # 1:1 不缩放
        "free": true,                                  # 自由定位：挂到宿主叠加层，位置不被父级布局覆盖
        "open_at": Enums.OpenAt.ANCHOR_RIGHT_OUT,      # 挂在宿主右侧外面的那一列里
        "events": [hold_bind] + tip_events(tip),
    }


## "悬停说明"浮窗的配置（`Tip` 预设与服务多扇窗的测试都用它）：正文读**外壳的** content
## （`open(..., content="…")` 合并进来的就是它；`content_cmd` 里的 `@self` = 写这条指令的元素，
## 见 UIBase.refresh）⇒ **一份预设能说明任何东西**，不必一个说明建一个预设。
static func tip_cfg(fallback: String) -> Dictionary:
    return {
        "size": [0, 0],
        "free": true,
        # **贴着被说明的那个东西**（锚点 = 那段字/那个按钮），并**挑离鼠标最近的那个角**：
        # 就这一个 open_at 值（`ANCHOR_NEAREST` = 取"锚点顶点周围的四角"、按"离指针最近"排）⇒
        # 指针在哪边就往哪边冒（窗口再长、指针再靠边都看得见），而浮窗**不压住指针**——
        # 贴指针那条路试过：指针一落进浮窗，事件从浮窗冒泡到锚点，`meta_hover` 变 null ⇒
        # 会被当成"离开链接"当场收掉（详见 UIInteract_Meta 文件头那条 ⚠️）。
        # （"离指针最近"也可以写成别的策略 + `nearest: true`，见 Enums.OpenAt；这里贴锚点，用前者。）
        "open_at": Enums.OpenAt.ANCHOR_NEAREST,
        "children": [
            ["Text", "UI_Label", {
                "content": fallback,                    # 字面值 = 没带内容进来时的兜底
                "content_cmd": "@self.parent.config.content",
                "max_chars": SysCfg.ui_view_chars,
            }],
        ],
    }


## 一块"**会滚的文本**"的正文子元素——原来 `UI_Scroll` 干的活，现在就是"普通 `UI_Panel` + 这一项"：
## 外壳（面板）的 `config["content"]` 是显示内容，这里读出来铺到一块**撑满宽、自动换行**的文本上。
## `wrap: true` = 宽度交给容器（见 `UI_Label._width_from_parent`）⇒ 文字照面板给到的宽折行、只报该多高。
## 面板 `size` **两维都写数**（或配 `scroll` 上限）时，超出可视区的部分在框内滚动
## ——面板内容盒外面本来就有滚动容器，竖向滚动条自动出（见 UI_Panel 文件头）。
## 用法：
##   ["Show", "UI_Panel", {"size": [260, 140], "children": [UIPreset_Basic.text_item("（空）")]}]
## **改内容写的是外壳的 `config["content"]`**，之后要刷**整棵**（`refresh_tree()`）——
## 正文是子元素，只刷外壳那一层它不会跟着变（`UISys.refresh_all()` 也行）。
## 被谁用：MiniHUD 的 `Info`（本文件）、UIPreset_Test 的 `TestShow`。
static func text_item(fallback: String = "") -> Array:
    return ["Text", "UI_Label", {
        "content": fallback,                        # 字面值 = 还没人写内容时的兜底
        "content_cmd": "@self.parent.config.content",
        "wrap": true,
    }]


var values: Array[Array] = [
    # 悬停说明的小浮窗（关闭 / 缩放按钮、可折叠标题的箭头都用它，见 UIInteract_Fold._sym_meta）：
    # 配置来自 `tip_cfg()`，**内容由开它的那一句带进来**（`open(..., content="…")`）⇒ 一份预设够全项目用。
    ["Tip", "UI_Panel", tip_cfg("（说明）")],
    ["MiniHUD", "UI_Panel", {
        # 高度写 0 = **随内容**：以前写死 220，而里面只有"标题 + 滚动区"两行 ⇒ 底下剩一大段空白；
        # 以后往里加内容它自己长，不用回来改这个数（宽仍定死 320，横向不要跟着文字跳）。
        "position": [30, 30], "size": [320, 0],
        # 右键这块 UI → 开"Menu"（菜单挂在这个面板下，菜单项里用 host 就指回它——不必数级数）
        # 第一/第三个参数都传 self：第一个没有 anchor 时才用来当挂载点，第三个既是位置锚点
        # 又是挂载点（菜单链因此是一棵子树）；摆在哪由 Menu 自己的 open_at 声明（POINTER = 指针处）
        # 整块面板的"按住可拖"不写死在这儿：菜单项"启用拖拽"用 switch_value 往这个列表里加/减
        # QName.UI_event_pointer1_drag（默认没有 ⇒ 面板体不可拖；标题栏用的是 _host 版那两条）。
        "events": [QName.UI_event_pointer2_menu],
        "children": [
            # 标题栏：只显示文本；按住 → drag 登记后由 AutoSys 每帧拖这个窗口（host）
            # （event = 事件名 = 状态名 = Key 名，由 指令系统（`@self`/`@host`/`@event`） 补成带引号的参数；松手 AutoSys 自动停）
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "events": [QName.UI_event_pointer1_drag_host],
            }],
            # 关闭"按钮"：图标式（和 CloseButton 预设同一套），贴在窗口右上角
            UIPreset_Basic.close_item(),   # 图标式关闭（右上角）：和 CloseButton 预设同一张图 / 同一套指令
            # 滚动内容：展示本元素 config["content"]（改内容 = 写它 + 刷整棵，见 UIPreset_Basic.text_item）
            # 尺寸写死 = 定死的可视区，内容多了在框内滚（面板的滚动容器自动出竖向滚动条）
            ["Info", "UI_Panel", {
                "size": [280, 120],
                "children": [text_item("初始内容")],
            }],
            # 图片示例：content 填纹理路径即可显示；改图 = 写它的 config["content"] + 一条刷新
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
    # 关闭按钮：**就是上面 close_cfg() 那份配置**，当独立预设开出来（元素侧没有任何专门逻辑）：
    #   UIInteract.open(宿主, "CloseButton", 宿主)   ← 挂到宿主下、开在宿主内部右上角
    #   UIInteract.close(宿主, "CloseButton")        ← 移除（隐藏；重开仍走 open）
    ["CloseButton", "UI_Image", close_cfg()],
    # 两个手柄：等比缩放（整块放大，字也变大）/ 改宽高（内容跟着折行，见 UIInteract_Resize）。
    # 同一个角上 ⇒ 自动排成一行，**后加的在左边**（见 UI_Panel._corner_box）⇒
    # "先开 ResizeButton、再开 SizeGrip" = 等比缩放在右、改尺寸在左。
    ["ResizeButton", "UI_Image", handle_cfg(RESCALE_ICON, QName.UI_event_pointer1_rescale_host, "等比缩放")],
    ["SizeGrip", "UI_Image", handle_cfg(RESIZE_ICON, QName.UI_event_pointer1_resize_host, "改尺寸")],
]
