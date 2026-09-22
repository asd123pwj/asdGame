class_name UIPreset_Basic
extends ConfigBase

"""
name: String
ui_name: String
config: Dictionary

交互不是开关，而是"事件→指令"：config["events"] 是 [事件名, 指令串] 的列表，事件发生即发指令。
事件名就是状态名（见 Archetype_System 的 statuses，如 "Mouse Left"）——UI 不关心键位，
键位只在状态层配置；hover 变化用 QName.pointer_enter / QName.pointer_exit。
占位符只有 self（自身）、host（本条链的**管理对象**）与 event（事件名）；
取父级/内容一律在它上面接着写取值链：
  @self.parent = 挂载对象（父 UI），self.config.content = 自己的显示内容，
  host = 管理对象（默认沿 parent 爬到顶那个 UI；也可以在某一层 config["host"] 写**注册名**（实例 ID 也认）指定成别的 UI，
         或 open 时给 host=@self）——菜单项/深层子元素用它，不必数 @self.parent 的级数。
交互指令宿主为 UIInteract（close/open/toggle/drag/rescale/fade_to/begin_edit/end_edit/switch_value/set_top）；
"写内容 / 对调配置"不需要专门交互：通用指令 Utils.write / Utils.swap + 一条刷新（详见 Script/UI/UI.md）。

原子元素（显示/交互有明显差异的才做子类）：
  UI_Panel  面板容器（竖排布局，用于堆叠子元素）
  UI_Label  文本（兼作"按钮"：配置 press 指令即可，无需单独 Button 类）
  UI_Image  图片（content = 纹理路径；改图 = 写 config["content"] + refresh("content")）
  UI_Scroll 滚动文本（content = 多行文本；写 config["content"] + refresh("content") 即改展示）
组合按钮 = Panel(背景) + Label(文字) 直接用配置堆叠，不写子类。
开关式按钮（可选框）也不用专门元素：同一个元素上写两套配置（events/content 与 events_2/content_2），
点击时用 Utils.swap 对调、再 @self.refresh("content") 即可——见 Config/UI/UIPreset_Menu.gd 的 CloseToggle。

预设也是"普通 UI"，所以重复出现的东西（关闭按钮 CloseButton、缩放手柄 ResizeButton）都做成预设、
用 UIInteract.open / close 开与关，不写专门函数。

注意：ScrollContainer 默认最小尺寸为 0，UI_Scroll 必须用 size 配置可视区大小，否则不可见。
"""
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", {
        "position": [30, 30], "size": [320, 220],
        # 右键这块 UI → 开"Menu"（菜单挂在这个面板下，菜单项里用 host 就指回它——不必数级数）
        # 第一/第三个参数都传 self：第一个没有 anchor 时才用来当挂载点，第三个既是位置锚点
        # 又是挂载点（菜单链因此是一棵子树）；摆在哪由 Menu 自己的 open_at 声明（POINTER = 指针处）
        # 整块面板的"按住可拖"不写死在这儿：菜单项"启用拖拽"用 switch_value 往这个列表里加/减
        # QName.UI_event_mouseLeft_drag（默认没有 ⇒ 面板体不可拖；标题栏用的是 _host 版那两条）。
        "events": [QName.UI_event_mouseRight_menu],
        "children": [
            # 标题栏：只显示文本；按住 → drag 登记后由 AutoSys 每帧拖这个窗口（host）
            # （event = 事件名 = 状态名 = Key 名，由 指令系统（`@self`/`@host`/`@event`） 补成带引号的参数；松手 AutoSys 自动停）
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "events": [QName.UI_event_mouseLeft_drag_host],
            }],
            # 关闭"按钮"：就是文本元素 + "Mouse Left"(左键按住) 指令（点它关掉这个窗口）
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [QName.UI_event_mouseLeft_close_host],
            }],
            # 滚动内容：展示本元素 config["content"]（改内容 = 写它 + @self.refresh("content")）
            # ScrollContainer 最小尺寸为 0，必须给 size 配置可视高度
            ["Info", "UI_Scroll", {
                "content": "初始内容",
                "size": [280, 120],
            }],
            # 图片示例：content 填纹理路径即可显示；改图 = 写它的 config["content"] + 一条刷新
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
    # 关闭按钮：贴到"锚点 UI"的右上角，点它关掉自己挂着的那个 UI。
    # **它就是普通 UI 预设**，所以"给某个 UI 加/减关闭按钮"不需要专门函数，直接开/关这个预设即可：
    #   UIInteract.open(宿主, "CloseButton", 宿主)   ← 挂到宿主下、开在宿主内部右上角
    #   UIInteract.close(宿主, "CloseButton")        ← 移除（隐藏；重开仍走 open）
    # 图标 = content（UI_Image 的 content 就是那张图，换图 = 写它的 config["content"] + 刷新）；尺寸照 Unity 的 16*2。
    ["CloseButton", "UI_Image", {
        "content": "res://Material/Texture/UI/CloseButtom_16.png",
        "size": [16 * 2, 16 * 2],
        "free": true,                                  # 自由定位：挂到宿主叠加层，位置不被父级布局覆盖
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT_IN,   # 开在锚点（宿主自己）内部的右上角
        # 点它关掉它所在的窗口（host = 沿 parent 爬到顶那个 UI ⇒ 挂到谁身上都指得对）
        "events": [QName.UI_event_mouseLeft_close_host],
    }],
    # 缩放按钮：贴到"锚点 UI"的右下角，按住拖动等比缩放它挂着的那个 UI（像 Windows 拖窗口角，但是等比）。
    # 元素侧只有这一条"按住"：rescale 登记后由 AutoSys 每帧调 rescaling 缩放它挂着的 UI；
    # 不满足（松手）时 AutoSys 自己把这条登记删掉，所以不用写"松开"，也不用存任何跨帧状态。
    # 用 Hold 而不是 Press：它只在"开始按住"那一下触发（不是每帧）。
    ["ResizeButton", "UI_Image", {
        "content": "res://Material/Texture/UI/ResizeButtom_16.png",
        "size": [16 * 2, 16 * 2],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN,   # 开在锚点（宿主自己）内部的右下角
        "events": [QName.UI_event_mouseLeft_rescale_host],
    }],
]
