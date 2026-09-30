class_name UIPreset_Menu
extends ConfigBase

""" ---------- 菜单配置 ----------
一个菜单 = 普通 UI（UI_Panel）+ 一份配置，**没有专属类**：
多出来的只是 open_at（开在哪）/ close_on_blur（失焦关闭）/ free（自由定位）三项，
都由 UISys 统一读配置处理。所以"换一套配置"就等于换一种菜单管理方式。

菜单链是一棵**子树**：子菜单挂在"触发它的那个菜单项"下（见 UISys 的挂载规则）。
菜单项作用的都是**同一个宿主**（那个窗口），可它们在链里的层级深浅不一 ——
所以**别数 `@self.parent` 的级数，用 `host`**：`host` = 沿 parent 爬到顶那个 UI（窗口本身），
不论中间包多少层（比如给菜单项再套一个可折叠分组），都指向同一个对象，加减层级不用改指令：
  RoleData
   └─ Menu(菜单A)            ← 右键 RoleData 打开，挂在 RoleData 下
      ├─ Close               → UIInteract.close(@host)                    (host = RoleData)
      └─ Edit(菜单项)        → UIInteract.open(@self, "MenuEdit", @self)   (菜单B 挂在 Edit 下：self = 挂载点)
         └─ MenuEdit(菜单B)
            ├─ CloseToggle(开关式按钮) → 点一下"做事 + 换一套配置"：先开/关 RoleData 的 "X" 按钮，
            │                            再把 events↔events_2、content↔content_2 对调，于是下次点击走另一套
            │                            关闭按钮本身就是普通预设（CloseButton，见 UIPreset_Basic.gd），
            │                            所以"加/减"就是开/关它，没有专门函数：
            │                            events   : UIInteract.open(@host, "CloseButton", @host)
            │                                       + Utils.swap("@self.config.events", "@self.config.events_2")
            │                                       + Utils.swap("@self.config.content", "@self.config.content_2")
            │                                       + @self.refresh("content")
            │                            events_2 : 同样几条，第一条换成 UIInteract.close(@host, "CloseButton")
            ├─ EnableDrag     → UIInteract.switch_value(@host, "events", QName.UI_event_pointer1_drag)
            └─ Advanced       → UIInteract.open(...)   (UI 编辑器：通用 open 开出来；内容由元素自己按配置铺)
`self` 与 `host` 的分工：`self` = 配了这条指令的元素本身（当挂载点/锚点用它），
`host` = 它所在的那个窗口（"管理宿主"用它）。另见 UI.md 的"占位符只有三个词"。
（"关父级时整条链一起关""鼠标在子菜单上不会被判失焦"都由这棵树自动成立。）

四个预设：
  Menu        : 关闭 / 复制名称 / 绑定 ▸ / 菜单编辑
  MenuEdit    : 关闭按钮 / 缩放手柄 / 改尺寸手柄（三个**开关式按钮**：两套配置对调） / 启用拖拽 / 高级管理
  DesktopMenu : **常态右键菜单**——点在**空地上**右键开的那一扇（`open_at = POINTER`、独立 UI、开在指针处）。
                第一项开"指针下那个角色"的看板（没抓到角色就写成"（当前无角色）"占位、点了不做事），
                第二项固定开 **SYS 角色**的看板，第三项开"此格瓦片查看"（`MapCell`，见 UIPreset_MapCell）。
                由 SYS 角色上那条状态 + 一条快捷指令开出（`QName.desktop_menu`，见 Archetype_System）。
  （"内容对象 ▸"不占预设：开通用 Editor 编辑宿主的 content_cmd）
（"UI 编辑器"= 外壳 Config/UI/UIPreset_Editor.gd + 内容元素 Script/UI/UI/UI_Editor.gd：
 打开就是一条通用 open，内容由元素按 source / special / kinds 自己铺，见 UI.md 的"UI 编辑器"一节。）

开启位置由各自的 open_at 声明（Enums.OpenAt）：右键菜单开在指针处，多级菜单开在触发项右上角。

由宿主 UI 的配置决定何时开哪个，例如：
  "events": [["Pointer 2 Hold", "UIInteract.open self Menu self"]]
（第三个参数 = 位置锚点，同时也是**挂载点**：子菜单因此挂在触发它的那个菜单项下；
 POINTER 策略下开在指针处，但仍然用它决定挂在谁下面，所以菜单项里通常传 self。
 指令串的参数只有中间带空格时才需要引号，如 "Pointer 1 Hold"；其余直接写名字。）
"""

var values: Array[Array] = [
    # 标准菜单：固定两项，都作用于宿主 UI
    ["Menu", "UI_Panel", {
        "size": [150, 0],
        "free": true,                              # 自由定位：挂到宿主叠加层，位置不被父级布局覆盖
        "open_at": Enums.OpenAt.POINTER,           # 开在指针处（右键菜单）
        "children": [
            # 关闭 = 关掉宿主 UI（不是关菜单）。
            # **这里保持文字项**：它是菜单里的一行（关的是宿主，不是这个弹窗）；窗口角上的那个图标式关闭
            # 是 `UIPreset_Basic.close_item()`（一览 / 编辑器 / RoleData 用的就是它）。
            ["Close", "UI_Label", {
                "content": "关闭",
                "events": [[QName.pointer1_hold, "UIInteract.close(@host)"]],
            }],
            # （原来的"绑定 ▸"挪进了"菜单编辑 ▸"里，且改成写 `content_cmd`——
            #   "这个 UI 显示/编辑哪个对象"现在是通用配置项，不再需要 config["bind"] 那层转手。）
            # 菜单编辑：悬停即在它右上角弹出子菜单（多级菜单 = 菜单开菜单）
            # close_on_move=true：鼠标挪开就自动收起来（写在这儿而不是 MenuEdit 预设里——
            # 关闭行为只跟"在哪开、为什么开"有关，每加一层子菜单都要记得抄一遍预设很容易漏）
            ["Edit", "UI_Label", {
                "content": "菜单编辑 ▸",
                "events": [[QName.pointer_enter,
                    'UIInteract.open(@self, "MenuEdit", @self, close_on_move=true)']],
            }],
        ],
    }],
    # 菜单编辑的子菜单：两项都作用于宿主 UI
    # 关闭行为不写在这儿：开它的那句（Menu 的 Edit 项）传了 close_on_move=true
    ["MenuEdit", "UI_Panel", {
        "size": [170, 0],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,  # 开在触发它的那个菜单项的右上角顶点
        "children": [
            # 复制名称：把**宿主**的登记名复制出去（系统剪贴板 + UISys.copied_name，供"内容对象 ▸"填进来）
            # 登记名是**数据**——登记时就热更新进了 config["reg_name"]（见 UISys._register_tree），
            # 所以这里就是"内嵌取值 + 一条通用命令"，没有专门的"复制名称"函数。
            # host = 宿主（沿 parent 爬到顶那个 UI）——不用数级数，本项套多深都指它
            ["CopyName", "UI_Label", {
                "content": "复制名称",
                "events": [[QName.pointer1_hold,
                    "Utils.copy(@host.config.reg_name)"]],
            }],
            # 内容对象：**就是开那个通用编辑器**（`Editor`），让它编辑宿主的 `content_cmd` 这一项。
            # 这一项是个**字符串** ⇒ 自适应编辑器按类型选模板，出来就是一个文本输入框 + 回车写回；
            # 不需要为"填一个路径"再写一个专门的面板（原来那个 Editor（内容对象） 已删）。
            # `content_cmd="@host.config.content_cmd"` 说的就是"要编辑的对象 = 宿主的 content_cmd"。
            ["ContentCmd", "UI_Label", {
                "content": "内容对象 ▸",
                "events": [[QName.pointer_enter,
                    'UIInteract.open(@self, "Editor", @self, close_on_move=true, content_cmd="@host.config.content_cmd", open_at=%s)' % Enums.OpenAt.ANCHOR_TOP_RIGHT]],
            }],
            # 关闭按钮：**开关式按钮**——"加 / 减关闭按钮"就是开 / 关一个普通 UI 预设（CloseButton，
            # 见 UIPreset_Basic.gd）；形状走通用模板（见 UIPreset_Basic.toggle_item）。
            UIPreset_Basic.toggle_item("CloseToggle", "启用关闭按钮", "移除关闭按钮",
                'UIInteract.open(@host, "CloseButton", @host)',
                'UIInteract.close(@host, "CloseButton")'),
            # 给宿主 UI 加/减"按住拖动"：**不写专门函数，就是对调它的两套 events**
            # （和 CloseToggle 一个路子：同一个元素上写两套配置，点一下换一套）。
            # 所以宿主 UI 的预设里要同时给 events / events_2（一套含拖动绑定、一套不含）。
            # 给宿主 UI 加/减"按住拖动"：**不写专门函数**——直接开关宿主 events 列表里的那一条绑定
            # （switch_value：有就删、没有就加；"那一条"就是 QName 里的 UI_event_pointer1_drag，
            #  所以指令串只有一处、不必在宿主预设里预摆两套 events 手工同步）。
            ["EnableDrag", "UI_Label", {
                "content": "启用拖拽",
                "content_2": "移除拖拽",
                # events 那条是裸数据（不用刷）；只有换过的 content 要刷
                "events": [[QName.pointer1_hold,
                    'UIInteract.switch_value(@host, "events", QName.UI_event_pointer1_drag)'
                    + '\vUtils.swap("@self.config.content", "@self.config.content_2")'
                    + '\v@self.refresh("content")']],
            }],
            # 两个手柄的开关（同 CloseToggle：开 / 关一个普通预设，形状走通用模板）：
            #   · ResizeButton = 等比缩放手柄（说明文字"等比缩放"，见 UIPreset_Basic.handle_cfg）；
            #   · SizeGrip     = 改尺寸手柄（说明文字"改尺寸"）。
            # 注意同一个坑：窗口若**自带**某个手柄（元素名 = 预设名），开关复用的就是它。
            UIPreset_Basic.toggle_item("RescaleToggle", "启用缩放手柄", "移除缩放手柄",
                'UIInteract.open(@host, "ResizeButton", @host)',
                'UIInteract.close(@host, "ResizeButton")'),
            UIPreset_Basic.toggle_item("SizeGripToggle", "启用改尺寸手柄", "移除改尺寸手柄",
                'UIInteract.open(@host, "SizeGrip", @host)',
                'UIInteract.close(@host, "SizeGrip")'),
            # UI 编辑器：开"能编辑这个 UI 全部内容"的菜单（config 每一项 + 子UI，递归；子UI默认收起）。
            # **就一条通用 open**：外壳与内容都在 UIPreset_Editor 里声明好了，元素在 build 时自己铺。
            # 见 Config/UI/UIPreset_Editor.gd、Script/UI/UI/UI_Editor.gd 与 UI.md 的"UI 编辑器"。
            ["Advanced", "UI_Label", {
                "content": "编辑",
                # 编辑目标写明白：`content_cmd="host.config"` = 编辑**这个 UI 自己**（相对写法，见 UI_Editor）。
                "events": [[QName.pointer1_hold,
                    'UIInteract.open(@host, "Editor", @host, host=@host, content_cmd="host.config")']],
            }],
        ],
    }],
    # **常态右键菜单**：点在**空地上**右键开的那一扇（谁开的见 Archetype_System 里 `QName.desktop_menu`）。
    # 它是**独立 UI**（没有宿主、没有锚点）⇒ 开在指针处、点别处关（`close_on_blur` 由开它的那一句传）。
    # 两项都是"开角色数据看板"（`RoleData`），差的只是**看谁**：
    #   · OpenChar：看**指针下那个角色**——开菜单那句把 `content=PointerDetect.hover_char` 传了进来，
    #     文字与动作都由下面两个静态函数按它算（没角色 ⇒ 写"（当前无角色）"、点了不做事）；
    #   · OpenSYS ：固定看 **SYS 角色**（系统角色：看板里"状态 / 快捷"那两格本来就是看它，见 UIPreset_View.CELLS）；
    #   · OpenCell：开"此格瓦片查看"（`MapCell`，见 UIPreset_MapCell）——看**指针停的那一格**各子层放了什么。
    ["DesktopMenu", "UI_Panel", {
        "size": [190, 0],
        "free": true,                              # 自由定位：挂到 UI 根（没有宿主）的叠加层
        "open_at": Enums.OpenAt.POINTER,           # 开在指针处（和窗口右键菜单同一个策略）
        "children": [
            ["OpenChar", "UI_Label", {
                # 文字与动作都读"菜单上存着的那个角色"（见 _menu_char）；`@self.parent` = 这扇菜单
                "content_cmd": "UIPreset_Menu.char_option_text(@self.parent)",
                "events": [[QName.pointer1_hold,
                    "UIPreset_Menu.open_char_window(@self.parent)"]],
            }],
            ["OpenSYS", "UI_Label", {
                "content": "打开 SYS 角色的窗口",
                "events": [[QName.pointer1_hold,
                    'UIInteract.open(preset_name="RoleData", content_cmd="%s")' % SYS_CHAR_PATH]],
            }],
            # 查看"点到的这一格"各子层放了哪些瓦片（窗口 + 实时监控 + 可改 X/Y/Layer，见 UIPreset_MapCell）。
            # 把**指针那一格**写进窗口的 x / y：菜单就开在指针处，指针还停在那格上，所以正是"右键点的那一格"。
            ["OpenCell", "UI_Label", {
                "content": "查看此格瓦片",
                "events": [[QName.pointer1_hold,
                    'UIInteract.open(preset_name="MapCell", cell=PointerDetect.map_position)']],
            }],
        ],
    }],
    # （原来的 Editor（内容对象） 面板已删："填一个对象路径"就是**开通用编辑器去编辑宿主的 content_cmd**
    #   ——见菜单编辑里的"内容对象 ▸"项。编辑单个值不再各写一个面板，都用 UI_Editor。）
]


## ---------- 常态右键菜单（DesktopMenu）那两项 ----------
## 菜单的 `config["content"]` 存着"**开菜单那一刻指针下的角色**"（开它的快捷指令传的
## `content=PointerDetect.hover_char`；在空地上点就是 null）——下面两件事都从它读，别再各处自己取。
const DESKTOP_MENU_OPTION := "打开角色窗口"
const DESKTOP_MENU_NO_CHAR := "（当前无角色）"
const SYS_CHAR_PATH := "@Char/SYS"


## 常态菜单第一项的**文字**：有角色 = "打开角色窗口：<角色名>"；没角色 = "打开角色窗口（当前无角色）"。
## **没角色时只是个占位**：那种"不可按的按钮"的样子还没做（用户要求先别做，先用括号说明），
## 点了也不做事（见 open_char_window）。
## 被谁用：预设里那一项的 `content_cmd`（`UIPreset_Menu.char_option_text(@self.parent)`）。
static func char_option_text(menu: UIBase) -> String:
    var char_: Character = _menu_char(menu)
    if char_ == null:
        return DESKTOP_MENU_OPTION + DESKTOP_MENU_NO_CHAR
    return "%s：%s" % [DESKTOP_MENU_OPTION, char_.name]


## 常态菜单第一项**点了做什么**：把角色数据看板开到那个角色身上（`content_cmd` 写它的注册名 ⇒
## 看板六个格子一起看它，见 UIPreset_View）。
## **没角色就什么都不做**（那是占位项）。**开 UI 仍走指令**：`UIInteract.open` 是全项目唯一的开启入口，
## 这里只是按当场抓到的角色把那条指令拼出来（同"开哪一扇"都只写一处的规矩）。
## 被谁用：预设里那一项的 events。
static func open_char_window(menu: UIBase) -> void:
    var char_: Character = _menu_char(menu)
    if char_ == null:
        return
    Msg.send_cmd('UIInteract.open(preset_name="RoleData", content_cmd="@%s")' % RegSys.name_of(char_))


## 这扇常态菜单**当场抓到的那个角色**：菜单 config 里存的那一个（没抓到 / 已经没了给 null）。
## 开菜单的快捷指令传的是 `PointerDetect.hover_char`（"指针下那个角色"）——那一刻还没有这扇菜单，
## 所以判的是"右键点在谁身上"，之后指针挪到菜单上也不影响（值已经存下来了）。
## 被谁用：char_option_text / open_char_window。
static func _menu_char(menu: UIBase) -> Character:
    if menu == null:
        return null
    var c: Variant = menu.config.get("content")
    return c as Character
