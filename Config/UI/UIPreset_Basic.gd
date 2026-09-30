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
##   · 当 `children` 里的一项：`UIPreset_Basic.close_item(),`（窗口自带，如一览 / 编辑器 / RoleData）
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


## **开关式按钮**（可选项 / 开关项）的**片段构造器**：同一个元素上写两套配置，点一下"做事 + 换一套"，
## 下次点击自然走另一套。项目里好几处都是这个形状（菜单的"启用关闭按钮 / 缩放手柄 / 改尺寸手柄"、
## 地图格窗口的"实时监控"）——**差异只有三处**，所以收成一个模板（同 UIInteract_Fold.title_item）：
##   1. 两套文字：`content`（现在这态显示什么）/ `content_2`（对调后显示什么）；
##   2. 两套事件的第一条命令：`cmd`（现在点击做什么）/ `cmd_2`（对调后点击做什么）；
##   3. （可选）其余配置：`cfg` 里写（如 `free` / `position` / `size`）。
## **后面那两条"对调 + 刷新"完全一样**，模板里统一拼好，不再每处抄一遍：
##   `Utils.swap(events ↔ events_2)` ＋ `Utils.swap(content ↔ content_2)` ＋ `refresh("content")`
##   （只刷 content：events 是派发时才读的裸数据，刷它没意义）。
## `name_` 由用它的那一处给（菜单里那三个就叫 CloseToggle / RescaleToggle / SizeGripToggle）。
static func toggle_item(name_: String, content: String, content_2: String,
        cmd: String, cmd_2: String, cfg: Dictionary = {}) -> Array:
    var tail: String = '\vUtils.swap("@self.config.events", "@self.config.events_2")' \
        + '\vUtils.swap("@self.config.content", "@self.config.content_2")' \
        + '\v@self.refresh("content")'
    var item: Dictionary = {
        "content": content, "content_2": content_2,
        "events": [[QName.pointer1_hold, cmd + tail]],
        "events_2": [[QName.pointer1_hold, cmd_2 + tail]],
    }
    item.merge(cfg, true)
    return [name_, "UI_Label", item]


## 悬停多久才弹说明（秒）：指针**停住**满这么久才弹；期间每动一下都重新计时（见 tip_open_cmd）。
const TOOLTIP_DELAY := 0.5
## 说明浮窗的**预设名**（默认那扇 `Tip`）：要开"同形状的另一扇"（如 MetaTest 的 `Tip2`）就当参数传。
const TIP_PRESET := "Tip"


## **"打开说明浮窗"那条指令** —— **全项目的说明浮窗都从这儿来**（别处别再自己拼 open 指令）。
## 内容由调用方给，预设名默认那扇 `Tip`。做法是**包一层延时**（`TimeSys.after`，见 Script/Time/TimeSystem.gd）：
##   · 指针每动一下（`pointer_move`）都会再登记**同一条**指令 ⇒ 延时被**重置**，只有停住不动满
##     TOOLTIP_DELAY 才真的开；
##   · `cancel_on=QName.pointer_move` = **取消条件**：**鼠标一动就作废**（那是 SYS 角色上的瞬时状态，
##     由 PointerDetect 在派发"移动"事件之前发；所以指针挪开、停下、甚至原地动一下，这条待执行都会
##     先作废再由本次移动重新登记 ⇒ 只有"停在原地"才等得到）。取消条件统一是**角色状态名**（见 TimeSys.after）。
## 指令串用**单引号**括着传（里面还要写双引号，见 CommandParser 的"字符串字面量"那条）。
## 被谁用：tip_events（整块元素那条路）、tip_hover_bind（富文本链接那条路，UIInteract_Fold 也在用）。
static func tip_open_cmd(text_: String, preset: String = TIP_PRESET) -> String:
    var open_cmd: String = 'UIInteract.open(@self, "%s", @self, content="%s")' % [preset, text_]
    return "TimeSys.after(%s, '%s', cancel_on=\"%s\")" % [TOOLTIP_DELAY, open_cmd, QName.pointer_move]


## **富文本链接**用的那一对：`[事件名, 指令串]`（`UIInteract_Meta.as_meta` 要的形状）——"悬停这段字就弹说明"。
## **收窗不在这儿**：链接那一路由 `UIInteract_Meta` 管（它认"指针还在不在那扇浮窗上"）。
## 被谁用：UIInteract_Fold 的标题箭头（`_sym_meta`）；要"换个同形状的另一扇浮窗"就传第二个参数（预设名）。
static func tip_hover_bind(text_: String, preset: String = TIP_PRESET) -> Array:
    return [QName.pointer_move, tip_open_cmd(text_, preset)]


## **整块元素**（按钮 / 手柄这种"整块都算说明"的）用的那两条事件：悬停弹说明 ＋ 移开收窗。
## 文本里的链接不用它——那种走链接的 meta（见 tip_hover_bind）："这一行里哪几个字有说明"只有链接自己知道。
static func tip_events(text_: String) -> Array:
    return [
        tip_hover_bind(text_),
        [QName.pointer_exit, 'UIInteract.close(@self, "%s")' % TIP_PRESET],
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


## **底图三键**（`background` / `background_slice` / `background_stretch`）——三个键要一起写，
## 而"图 + 边距 + 中段填充"就那么几种组合，所以收成这一处，别在每个预设里各手写三行
## （`text_item`、`UIPreset_View` 的窗口竹框与格子卷轴，原来都是手写的三行）。
## `slice` / `stretch` 不写 = **竹制图那套规格**（64×64、四角 16、中段平铺）：全项目这批竹图都是
## 这个规格（`SysCfg.ui_bamboo_slice` / `ui_bamboo_stretch`）。
## **中段按原样平铺、不拉伸**：这批图的纹样有细节（竹节 / 纸面），拉伸会按面板尺寸等比放大成一条宽暗带。
## 用法：`cfg.merge(UIPreset_Basic.bg(图路径))`，或 `{...}.merged(...)` 接在字面量后面。
static func bg(path: String, slice: int = -1, stretch: String = "") -> Dictionary:
    return {
        "background": path,
        "background_slice": slice if slice >= 0 else SysCfg.ui_bamboo_slice,
        "background_stretch": stretch if stretch != "" else SysCfg.ui_bamboo_stretch,
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
## 被谁用：任何"要一块能滚的文本框"的地方；用法照上面那行示例写即可。
static func text_item(fallback: String = "") -> Array:
    var cfg: Dictionary = {
        "content": fallback,                        # 字面值 = 还没人写内容时的兜底
        "content_cmd": "@self.parent.config.content",
        "wrap": true,
        # **不配 `selectable`**（= 不能选中文字）：引擎不给 RichTextLabel 的 Ctrl+C，
        # 光能拖蓝一片、复制不了反而奇怪。要做"选中 + 复制"时再给这里配上（见 UI_Label 的那段说明）。
    }
    # 展示文本框的底：**横版竹卷轴**（`SysCfg.ui_text_background`）——输入框那面用竖版
    # （`UI_Input` 的默认底）；九宫格规格走 `bg()` 的默认值（竹图那套：16 + 平铺）。
    cfg.merge(bg(SysCfg.ui_text_background))
    return ["Text", "UI_Label", cfg]


var values: Array[Array] = [
    # 悬停说明的小浮窗（关闭 / 缩放按钮、可折叠标题的箭头都用它，见 UIInteract_Fold._sym_meta）：
    # 配置来自 `tip_cfg()`，**内容由开它的那一句带进来**（`open(..., content="…")`）⇒ 一份预设够全项目用。
    ["Tip", "UI_Panel", tip_cfg("（说明）")],
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
