class_name UIPreset_Menu
extends ConfigBase

""" ---------- 菜单配置 ----------
一个菜单 = 一个 UI_Menu 元素 + 一份配置（和 UI_Label/UI_Scroll 一样是普通 UI 配置，
只是多了 open_at / close_on_blur / free 三项）。所以"换一套配置"就等于换一种菜单管理方式。

这里放的是**右键菜单的内容**：菜单项是普通子 UI，事件绑定里
  $parent        = 菜单本身
  $parent.parent = 宿主 UI（菜单挂在宿主下）← 菜单项的功能都作用于宿主
于是"关闭"关的是宿主 UI（像右键窗口标题栏点关闭），菜单只是快捷方式。

三个预设：
  Menu      : 关闭 / 菜单编辑
  MenuEdit  : 添加关闭按钮 / 启用拖拽 / 高级编辑
  MenuEmpty : 高级编辑打开的空菜单（内容待补）

开启位置由各自的 open_at 声明（Enums.OpenAt）：右键菜单开在指针处，多级菜单开在触发项右上角。

由宿主 UI 的配置决定何时开哪个，例如：
  "events": [["Mouse Right", "UIInteract.open_ui $self Menu $self"]]
（第三个参数是位置锚点，POINTER 策略下忽略它，通常传 $self。
 指令串的参数只有中间带空格时才需要引号，如 "Mouse Left | Tick"；其余直接写名字。）
"""

var values: Array[Array] = [
    # 标准菜单：固定两项，都作用于宿主 UI
    ["Menu", "UI_Menu", {
        "size": [150, 0],
        "free": true,                              # 自由定位：挂到宿主叠加层，位置不被父级布局覆盖
        "open_at": Enums.OpenAt.POINTER,           # 开在指针处（右键菜单）
        "close_on_blur": true,                     # 失焦关闭：点菜单链外即销毁
        "children": [
            # 关闭 = 关掉宿主 UI（不是关菜单）
            ["Close", "UI_Label", {
                "content": "关闭",
                "events": [["Mouse Left", "UIInteract.close $parent.parent"]],
            }],
            # 菜单编辑：悬停即在它右上角弹出子菜单（多级菜单 = 菜单开菜单）
            ["Edit", "UI_Label", {
                "content": "菜单编辑 ▸",
                "events": [["Pointer Enter", "UIInteract.open_ui $parent.parent MenuEdit $self"]],
            }],
        ],
    }],
    # 菜单编辑的子菜单：三项都作用于宿主 UI
    ["MenuEdit", "UI_Menu", {
        "size": [170, 0],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,  # 开在触发它的那个菜单项的右上角顶点
        "close_on_blur": true,
        "children": [
            # 给宿主 UI 的右上角加一个关闭按钮（Label "X" 占位）
            ["AddClose", "UI_Label", {
                "content": "添加关闭按钮",
                "events": [["Mouse Left", "UIInteract.add_close_button $parent.parent"]],
            }],
            # 让宿主 UI 可以按住拖动
            ["EnableDrag", "UI_Label", {
                "content": "启用拖拽",
                "events": [["Mouse Left", "UIInteract.enable_drag $parent.parent \"Mouse Left | Tick\""]],
            }],
            # 高级编辑：另开一个空菜单
            ["Advanced", "UI_Label", {
                "content": "高级编辑 ▸",
                "events": [["Mouse Left", "UIInteract.open_ui $parent.parent MenuEmpty $self"]],
            }],
        ],
    }],
    # 高级编辑打开的空菜单：内容暂留空
    ["MenuEmpty", "UI_Menu", {
        "size": [150, 40],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,
        "close_on_blur": true,
        "children": [],
    }],
]
