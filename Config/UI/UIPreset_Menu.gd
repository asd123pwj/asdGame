class_name UIPreset_Menu
extends ConfigBase

""" ---------- 菜单配置 ----------
一个菜单 = 普通 UI（UI_Panel）+ 一份配置，**没有专属类**：
多出来的只是 open_at（开在哪）/ close_on_blur（失焦关闭）/ free（自由定位）三项，
都由 UiSys 统一读配置处理。所以"换一套配置"就等于换一种菜单管理方式。

菜单链是一棵**子树**：子菜单挂在"触发它的那个菜单项"下（见 UiSys 的挂载规则）。
菜单项作用的都是**同一个宿主**（那个窗口），可它们在链里的层级深浅不一 ——
所以**别数 `self.parent` 的级数，用 `host`**：`host` = 沿 parent 爬到顶那个 UI（窗口本身），
不论中间包多少层（比如给菜单项再套一个可折叠分组），都指向同一个对象，加减层级不用改指令：
  MiniHUD
   └─ Menu(菜单A)            ← 右键 MiniHUD 打开，挂在 MiniHUD 下
      ├─ Close               → UIInteract.close(host)                    (host = MiniHUD)
      └─ Edit(菜单项)        → UIInteract.open(self, "MenuEdit", self)   (菜单B 挂在 Edit 下：self = 挂载点)
         └─ MenuEdit(菜单B)
            ├─ CloseToggle(开关式按钮) → 点一下"做事 + 换一套配置"：先开/关 MiniHUD 的 "X" 按钮，
            │                            再把 events↔events_2、content↔content_2 对调，于是下次点击走另一套
            │                            关闭按钮本身就是普通预设（CloseButton，见 UIPreset_Basic.gd），
            │                            所以"加/减"就是开/关它，没有专门函数：
            │                            events   : UIInteract.open(host, "CloseButton", host)
            │                                       + Utils.swap("self.config.events", "self.config.events_2")
            │                                       + Utils.swap("self.config.content", "self.config.content_2")
            │                                       + self.refresh("content")
            │                            events_2 : 同样几条，第一条换成 UIInteract.close(host, "CloseButton")
            ├─ EnableDrag     → UIInteract.switch_value(host, "events", QName.UI_event_mouseLeft_drag)
            └─ Advanced       → UIInteract.open(self, "MenuEmpty", self)   (菜单C 挂在 Advanced 下)
`self` 与 `host` 的分工：`self` = 配了这条指令的元素本身（当挂载点/锚点用它），
`host` = 它所在的那个窗口（"管理宿主"用它）。另见 UI.md 的"占位符只有三个词"。
（"关父级时整条链一起关""鼠标在子菜单上不会被判失焦"都由这棵树自动成立。）

三个预设：
  Menu      : 关闭 / 复制名称 / 绑定 ▸ / 菜单编辑
  MenuEdit  : 关闭按钮（开关式按钮：两套配置对调） / 启用拖拽 / 高级编辑
  MenuBind  : "绑定 ▸"的子菜单——一个输入框，回车把名字记进宿主的 config["bind"]
  MenuEmpty : 高级编辑打开的空菜单（内容待补）

开启位置由各自的 open_at 声明（Enums.OpenAt）：右键菜单开在指针处，多级菜单开在触发项右上角。

由宿主 UI 的配置决定何时开哪个，例如：
  "events": [["Mouse Right", "UIInteract.open self Menu self"]]
（第三个参数 = 位置锚点，同时也是**挂载点**：子菜单因此挂在触发它的那个菜单项下；
 POINTER 策略下开在指针处，但仍然用它决定挂在谁下面，所以菜单项里通常传 self。
 指令串的参数只有中间带空格时才需要引号，如 "Mouse Left"；其余直接写名字。）
"""

var values: Array[Array] = [
    # 标准菜单：固定两项，都作用于宿主 UI
    ["Menu", "UI_Panel", {
        "size": [150, 0],
        "free": true,                              # 自由定位：挂到宿主叠加层，位置不被父级布局覆盖
        "open_at": Enums.OpenAt.POINTER,           # 开在指针处（右键菜单）
        "children": [
            # 关闭 = 关掉宿主 UI（不是关菜单）
            ["Close", "UI_Label", {
                "content": "关闭",
                "events": [[QName.mouseLeft, "UIInteract.close(host)"]],
            }],
            # 复制名称：把**宿主**的登记名复制出去（系统剪贴板 + UiSys.copied_name，供"绑定 ▸"填给别的 UI）
            # 登记名是**数据**——登记时就热更新进了 config["reg_name"]（见 UiSys._register_tree），
            # 所以这里就是"内嵌取值 + 一条通用命令"，没有专门的"复制名称"函数。
            # host = 宿主（沿 parent 爬到顶那个 UI）——不用数级数，本项套多深都指它
            ["CopyName", "UI_Label", {
                "content": "复制名称",
                "events": [[QName.mouseLeft,
                    "Utils.copy(host.config.reg_name)"]],
            }],
            # 绑定：悬停弹出子菜单，里面填"要发给哪个 UI"（输入框预填刚复制的名字，回车提交）
            # 传 self：子菜单挂在**这一项**下面（和"菜单编辑"一个规矩）；菜单项里管理宿主一律用 host
            # 打开就是通用的 open（close_on_move=true：挪开就收）；"预填 + 聚焦"是紧接着的另一条普通指令
            # （事件串本来就支持 \v 连多条，不必为此造一个特殊的"打开"命令）
            ["Bind", "UI_Label", {
                "content": "绑定 ▸",
                "events": [[QName.pointer_enter,
                    'UIInteract.open(self, "MenuBind", self, close_on_move=true)']],
            }],
            # 菜单编辑：悬停即在它右上角弹出子菜单（多级菜单 = 菜单开菜单）
            # close_on_move=true：鼠标挪开就自动收起来（写在这儿而不是 MenuEdit 预设里——
            # 关闭行为只跟"在哪开、为什么开"有关，每加一层子菜单都要记得抄一遍预设很容易漏）
            ["Edit", "UI_Label", {
                "content": "菜单编辑 ▸",
                "events": [[QName.pointer_enter,
                    'UIInteract.open(self, "MenuEdit", self, close_on_move=true)']],
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
                    [QName.mouseLeft, 'UIInteract.open(host, "CloseButton", host)'
                        + '\vUtils.swap("self.config.events", "self.config.events_2")'
                        + '\vUtils.swap("self.config.content", "self.config.content_2")'
                        + '\vself.refresh("content")'],       # 只刷 content（events 不显示，刷它没意义）
                ],
                "events_2": [
                    [QName.mouseLeft, 'UIInteract.close(host, "CloseButton")'
                        + '\vUtils.swap("self.config.events", "self.config.events_2")'
                        + '\vUtils.swap("self.config.content", "self.config.content_2")'
                        + '\vself.refresh("content")'],       # 只刷 content（events 不显示，刷它没意义）
                ],
            }],
            # 给宿主 UI 加/减"按住拖动"：**不写专门函数，就是对调它的两套 events**
            # （和 CloseToggle 一个路子：同一个元素上写两套配置，点一下换一套）。
            # 所以宿主 UI 的预设里要同时给 events / events_2（一套含拖动绑定、一套不含）。
            # 给宿主 UI 加/减"按住拖动"：**不写专门函数**——直接开关宿主 events 列表里的那一条绑定
            # （switch_value：有就删、没有就加；"那一条"就是 QName 里的 UI_event_mouseLeft_drag，
            #  所以指令串只有一处、不必在宿主预设里预摆两套 events 手工同步）。
            ["EnableDrag", "UI_Label", {
                "content": "启用拖拽",
                "content_2": "移除拖拽",
                # events 那条是裸数据（不用刷）；只有换过的 content 要刷
                "events": [[QName.mouseLeft,
                    'UIInteract.switch_value(host, "events", QName.UI_event_mouseLeft_drag)'
                    + '\vUtils.swap("self.config.content", "self.config.content_2")'
                    + '\vself.refresh("content")']],
            }],
            # 高级编辑：另开一个空菜单
            ["Advanced", "UI_Label", {
                "content": "高级编辑 ▸",
                "events": [[QName.mouseLeft, 'UIInteract.open(self, "MenuEmpty", self, close_on_blur=true)']],
            }],
        ],
    }],
    # "绑定"子菜单：一个输入框，回车把名字记进**宿主**的 config["bind"]。
    # 输入框预填"复制名称"复制的那个名字（由 UIInteract_Bind.paste_copied_name 填），常见流程是：
    #   右键目标 → 复制名称 → 右键要绑的 UI → 绑定 ▸ → 回车
    # 管理宿主一律用 host（菜单挂宿主、本项挂 Menu、MenuBind 挂本项 ⇒ 级数不必数）。
    # 关闭行为不写在这儿：开它的那一项传了 close_on_move=true（悬停展开 ⇒ 挪开就收）
    ["MenuBind", "UI_Panel", {
        "size": [220, 0],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,  # 开在"绑定 ▸"这一项的右上角
        "children": [
            ["Hint", "UI_Label", {"content": "绑定到（回车提交名称）"}],
            # 元素名随意（paste_copied_name 是"找子树里第一个输入框"，不认名字）
            ["Name", "UI_Input", {
                "size": [200, 0],
                "events": [
                    QName.UI_event_mouseLeft_edit,           # 点它进编辑
                    [QName.input_submit,
                        'Utils.write("host.config.bind", self.control.text)'
                        + '\vUIInteract.end_edit(self)']],
            }],
        ],
    }],
    # 高级编辑打开的空菜单：内容暂留空
    ["MenuEmpty", "UI_Panel", {
        "size": [150, 40],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,
        "children": [],
    }],
]
