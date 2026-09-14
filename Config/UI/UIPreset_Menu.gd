class_name UIPreset_Menu
extends ConfigBase

""" ---------- 菜单配置 ----------
一个菜单 = 普通 UI（UI_Panel）+ 一份配置，**没有专属类**：
多出来的只是 open_at（开在哪）/ close_on_blur（失焦关闭）/ free（自由定位）三项，
都由 UiSys 统一读配置处理。所以"换一套配置"就等于换一种菜单管理方式。

菜单链是一棵**子树**：子菜单挂在"触发它的那个菜单项"下（见 UiSys 的挂载规则），
所以 $parent 的级数是跟着链走的，写在菜单项上的指令按"数级数"定位宿主：
  MiniHUD
   └─ Menu(菜单A)            ← 右键 MiniHUD 打开，挂在 MiniHUD 下
      ├─ Close               → UIInteract.close $parent.parent           (2 级 = MiniHUD)
      └─ Edit(菜单项)        → UIInteract.open_ui $self MenuEdit $self   (菜单B 挂在 Edit 下)
         └─ MenuEdit(菜单B)
            ├─ AddClose       → $parent.parent.parent.parent              (4 级 = MiniHUD)
            ├─ EnableDrag     → 同上（$parent.parent.parent.parent）
            └─ Advanced       → UIInteract.open_ui $self MenuEmpty $self  (菜单C 挂在 Advanced 下)
也就是说：**链每深一层，到宿主就多一级 $parent**。
（"关父级时整条链一起关""鼠标在子菜单上不会被判失焦"都由这棵树自动成立。）

三个预设：
  Menu      : 关闭 / 菜单编辑
  MenuEdit  : 添加关闭按钮 / 启用拖拽 / 高级编辑
  MenuEmpty : 高级编辑打开的空菜单（内容待补）

开启位置由各自的 open_at 声明（Enums.OpenAt）：右键菜单开在指针处，多级菜单开在触发项右上角。

由宿主 UI 的配置决定何时开哪个，例如：
  "events": [["Mouse Right", "UIInteract.open_ui $self Menu $self"]]
（第三个参数 = 位置锚点，同时也是**挂载点**：子菜单因此挂在触发它的那个菜单项下；
 POINTER 策略下开在指针处，但仍然用它决定挂在谁下面，所以菜单项里通常传 $self。
 指令串的参数只有中间带空格时才需要引号，如 "Mouse Left | Tick"；其余直接写名字。）
"""

var values: Array[Array] = [
    # 标准菜单：固定两项，都作用于宿主 UI
    ["Menu", "UI_Panel", {
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
                "events": [["Pointer Enter", "UIInteract.open_ui $self MenuEdit $self"]],
            }],
        ],
    }],
    # 菜单编辑的子菜单：三项都作用于宿主 UI
    ["MenuEdit", "UI_Panel", {
        "size": [170, 0],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,  # 开在触发它的那个菜单项的右上角顶点
        "close_on_blur": true,
        "children": [
            # 给宿主 UI 的右上角加一个关闭按钮（Label "X" 占位）
            ["AddClose", "UI_Label", {
                "content": "添加关闭按钮",
                "events": [["Mouse Left", "UIInteract.add_close_button $parent.parent.parent.parent"]],
            }],
            # 让宿主 UI 可以按住拖动
            ["EnableDrag", "UI_Label", {
                "content": "启用拖拽",
                "events": [["Mouse Left", "UIInteract.enable_drag $parent.parent.parent.parent \"Mouse Left | Tick\""]],
            }],
            # 高级编辑：另开一个空菜单
            ["Advanced", "UI_Label", {
                "content": "高级编辑 ▸",
                "events": [["Mouse Left", "UIInteract.open_ui $self MenuEmpty $self"]],
            }],
        ],
    }],
    # 高级编辑打开的空菜单：内容暂留空
    ["MenuEmpty", "UI_Panel", {
        "size": [150, 40],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,
        "close_on_blur": true,
        "children": [],
    }],
]
