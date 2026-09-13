class_name UIPreset_Basic
extends ConfigBase

"""
name: String
ui_name: String
config: Dictionary

config 里的交互不是开关，而是"事件→指令"：press/move/release/submit 键各配一条指令串，
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
        "children": [
            # 标题栏：只显示文本；配置 move 指令 → 按住移动它整个父 UI 随鼠标拖动
            ["Title", "UI_Label", {
                "content": "MiniHUD（按住拖动）",
                "move": "UIInteract.drag $parent",
            }],
            # 关闭"按钮"：就是文本元素 + press 指令（点它关闭挂载对象即父 UI）
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "press": "UIInteract.close $parent",
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
