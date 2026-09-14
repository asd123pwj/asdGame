class_name UIPreset_Basic
extends ConfigBase

"""
name: String
ui_name: String
config: Dictionary

交互不是开关，而是"事件→指令"：config["events"] 是 [事件名, 指令串] 的列表，事件发生即发指令。
事件名就是状态名（见 Archetype_System 的 statuses，如 "Pointer Press Left"）——UI 不关心键位，
键位只在状态层配置；hover 变化用 PointerDetect.EVENT_POINTER_ENTER / EVENT_POINTER_EXIT。
占位符：$parent = 挂载对象（父 UI），$parent.parent = 祖父（链式任意级），$self = 自身。
交互指令宿主为 UIInteract（close/open/drag/fade_to/set_content）。

原子元素（显示/交互有明显差异的才做子类）：
  UI_Panel  面板容器（竖排布局，用于堆叠子元素）
  UI_Label  文本（兼作"按钮"：配置 press 指令即可，无需单独 Button 类）
  UI_Image  图片（content = 纹理路径，改图 = set_content(新路径)）
  UI_Scroll 滚动文本（content = 多行文本，set_content 即改展示）
组合按钮 = Panel(背景) + Label(文字) 直接用配置堆叠，不写子类。

注意：ScrollContainer 默认最小尺寸为 0，UI_Scroll 必须用 size 配置可视区大小，否则不可见。
"""
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", {
        "position": [30, 30], "size": [320, 220],
        # 右键这块 UI → 开"Menu"（菜单是它的子 UI，菜单项里 $parent.parent 就指回这个面板）
        # open_at 由 Menu 自己的配置声明（POINTER = 指针处），所以第三个参数随便传 $self
        "events": [["Mouse Right", "UIInteract.open_ui $self Menu $self"]],
        "children": [
            # 标题栏：只显示文本；"Mouse Left | Tick"(左键按住·逐帧) → 拖动它整个父 UI
            # （事件名即 Archetype_System 里那条状态的名字，逐帧的状态才能跟手）
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "events": [
                    ["Mouse Left | Tick", "UIInteract.drag $parent"],
                ],
            }],
            # 关闭"按钮"：就是文本元素 + "Mouse Left"(左键按住) 指令（点它关闭挂载对象即父 UI）
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [
                    ["Mouse Left", "UIInteract.close $parent"],
                ],
            }],
            # 滚动内容：展示本元素 content 属性（改内容 = UIInteract.set_content 或 set_content）
            # ScrollContainer 最小尺寸为 0，必须给 size 配置可视高度
            ["Info", "UI_Scroll", {
                "content": "初始内容",
                "size": [280, 120],
            }],
            # 图片示例：content 填纹理路径即可显示；改图 = UIInteract.set_content $parent "res://xxx.png"
            # ["Icon", "UI_Image", { "content": "res://icon.svg", "size": [32, 32] }],
        ],
    }],
]
