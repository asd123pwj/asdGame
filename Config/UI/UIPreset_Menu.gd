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
  MiniHUD
   └─ Menu(菜单A)            ← 右键 MiniHUD 打开，挂在 MiniHUD 下
      ├─ Close               → UIInteract.close(@host)                    (host = MiniHUD)
      └─ Edit(菜单项)        → UIInteract.open(@self, "MenuEdit", @self)   (菜单B 挂在 Edit 下：self = 挂载点)
         └─ MenuEdit(菜单B)
            ├─ CloseToggle(开关式按钮) → 点一下"做事 + 换一套配置"：先开/关 MiniHUD 的 "X" 按钮，
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

三个预设：
  Menu      : 关闭 / 复制名称 / 绑定 ▸ / 菜单编辑
  MenuEdit  : 关闭按钮（开关式按钮：两套配置对调） / 启用拖拽 / 高级管理
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
            # 是 `UIPreset_Basic.close_item()`（一览 / 编辑器 / MiniHUD 用的就是它）。
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
            # 关闭按钮：**开关式按钮**（普通 Label，不需要专门的开关元素）——同一个元素上写两套配置，
            # 点一下"做事 + 换一套配置"；一条事件串可以写多条命令（\v 分隔，见 CmdSys.execute）。
            # "加/减关闭按钮"就是开/关一个普通 UI 预设（CloseButton，见 UIPreset_Basic.gd），
            # 所以这里没有任何专门函数：第一条命令就是普通的 open / close。
            ["CloseToggle", "UI_Label", {
                "content": "启用关闭按钮",
                "content_2": "移除关闭按钮",
                # 两样里**只有 content 要刷**（它是显示内容）；events 是派发时才读的裸数据，刷它没意义
                # ——所以写成 refresh("content")，与"改了什么刷什么"对上（不传 key 是全刷）。
                # 路径写成带引号的字符串：引号里的内容不再被当成取值式，路径原样传给函数。
                # **指令串外层一律用单引号**（Godot 和 Python 一样两种引号都行）：
                # 里面要写双引号（路径/字符串参数）时就不用转义成 `\"`，看起来就是指令本身的样子。
                "events": [
                    [QName.pointer1_hold, 'UIInteract.open(@host, "CloseButton", @host)'
                        + '\vUtils.swap("@self.config.events", "@self.config.events_2")'
                        + '\vUtils.swap("@self.config.content", "@self.config.content_2")'
                        + '\v@self.refresh("content")'],       # 只刷 content（events 不显示，刷它没意义）
                ],
                "events_2": [
                    [QName.pointer1_hold, 'UIInteract.close(@host, "CloseButton")'
                        + '\vUtils.swap("@self.config.events", "@self.config.events_2")'
                        + '\vUtils.swap("@self.config.content", "@self.config.content_2")'
                        + '\v@self.refresh("content")'],       # 只刷 content（events 不显示，刷它没意义）
                ],
            }],
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
    # （原来的 Editor（内容对象） 面板已删："填一个对象路径"就是**开通用编辑器去编辑宿主的 content_cmd**
    #   ——见菜单编辑里的"内容对象 ▸"项。编辑单个值不再各写一个面板，都用 UI_Editor。）
]
