class_name Archetype_System
extends ConfigBase
## 内联写法演示：statuses/shortcuts 等字段的元素既可是"已存在的预设名"(字符串)，
## 也可直接是"内联配置"(字典/列表)——内联则现场创建并注册，重名会报错。
## 状态名/时间状态名统一走 QName（Config/QuickName.gd），别在这里写裸字符串。

var values: Array[Dictionary] = [
    {
        "name": "SYS",
        "packages": ["输入监控", "指针交互", "时间周期", "其它"],
    },
    {
        "name": "其它",
        "statuses": [
            {"name": "AlwaysSatisfied"},
        ],
    },
    {
        "name": "输入监控",
        "statuses": [
            # 指针移动不在状态层：它和 Pointer Enter / Pointer Exit 一样，由 PointerDetect._process 直接派发
            # 一个鼠标键三个状态：按下 / 按住 / 松开
            {"name": QName.pointer1_hold, "statuses": [[QName.mouseLeft, "Satisfied"]],},
            {"name": QName.pointer2_hold, "statuses": [[QName.mouseRight, "Satisfied"]],},
            {"name": QName.mouseLeft, "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.HOLD]],},
            {"name": QName.mouseRight, "keys": [[MOUSE_BUTTON_RIGHT, Enums.KeyStatus.HOLD]],},
            # 指针"这一帧动过"（**瞬时状态**）：由 PointerDetect._process 在派发 `Pointer Move` **事件之前**
            # 发一条瞬时检测。**同一个名字两种身份**——事件那份给 UI 元素（派发给当前 hover 的那个元素），
            # 状态这份给**状态层**：延时指令的取消条件写它即"鼠标一动就作废"
            # （`TimeSys.after(..., cancel_on=QName.pointer_move)`；配合"同一条重置"= 停住才执行）。
            {"name": QName.pointer_move, "auto_reset": true, "with_detect_transient": true},
            # 指针下**有没有 UI**（**保持型状态**：hover 变化时由 PointerDetect 手动开 / 关，同 QName.editing 那套）。
            # 常态右键菜单靠它判"点在空地上"（见下面那个依赖）。
            {"name": QName.pointer_on_ui, "with_detect_manual": true},
            # **常态右键菜单该开**：右键按住 ∧ 指针不在任何 UI 上 —— 两个依赖都满足才满足。
            # 满足时由"指针交互"里的快捷指令开出 "DesktopMenu"（开在指针处、点别处关，见 UIPreset_Menu）。
            {"name": QName.desktop_menu, "statuses": [
                [QName.pointer2_hold, "Satisfied"], [QName.pointer_on_ui, "Unsatisfied"]]},
            # **地图格实时监控**：一个**外部开关**（`QName.map_monitor_on`，保持型，由"此格瓦片"窗口里的
            # 可选项手动开/关，同 `QName.editing` 那套）＋"指针动过" —— 两个都满足时才实时刷新
            # "MapCell"（见 UIPreset_MapCell 的"实时监控"项）。
            {"name": QName.map_monitor_on, "with_detect_manual": true},
            {"name": QName.map_monitor, "statuses": [
                [QName.map_monitor_on, "Satisfied"], [QName.pointer_move, "Satisfied"]]},
            
            {"name": QName.right, "match_any": true, "keys": [[KEY_RIGHT, Enums.KeyStatus.HOLD], [KEY_D, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.up, "match_any": true, "keys": [[KEY_UP, Enums.KeyStatus.HOLD], [KEY_W, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.left, "match_any": true, "keys": [[KEY_LEFT, Enums.KeyStatus.HOLD], [KEY_A, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.down, "match_any": true, "keys": [[KEY_DOWN, Enums.KeyStatus.HOLD], [KEY_S, Enums.KeyStatus.HOLD]],},
            {"name": QName.submit, "statuses": [[QName.submit_on_what_keys, "Satisfied"], [QName.shift, "Unsatisfied"]],},
            {"name": QName.submit_on_what_keys, "match_any": true, "keys": [[KEY_ENTER, Enums.KeyStatus.HOLD], [KEY_KP_ENTER, Enums.KeyStatus.HOLD]],},
            {"name": QName.shift, "keys": [[KEY_SHIFT, Enums.KeyStatus.HOLD]],},
            # 编辑模式：进 / 出输入框编辑时由 UIInteract_Edit 手动开 / 关（**保持型**外部检测，不会自己复位）。
            # 于是"编辑中要屏蔽谁 / 回车算不算提交 / 菜单快捷键要不要让路"都能写成状态。
            {"name": QName.editing, "with_detect_manual": true},
            # F3：开 / 关 FPS 显示（Config/UI/UIPreset_FPS.gd）。
            {"name": QName.key_f3, "keys": [[KEY_F3, Enums.KeyStatus.HOLD]],},
        
        ],
    },
    {
        "name": "指针交互",
        "shortcuts": [
            # 每帧刷新指针目标（hover 变化时发 enter/exit），菜单 hover 展开依赖它：
            # 已挪进 InputSys._process（在派发按键之前，一帧只检测这一次），不再占一条 Tick 快捷
            # ["Pointer Refresh", QName.tick, "PointerDetect._process"],
            # FPS 显示也走这条"逐帧状态 + 快捷"的路（Config/UI/UIPreset_FPS.gd）：
            # 那条指令第一句就是"那扇 UI 没开就 return" ⇒ 没开时几乎零成本；开着也只在"取整变了"时才重排版。
            [QName.tick, QName.tick, 'UIPreset_FPS.tick()'],
            # 统一入口 PointerDetect.key("状态名")：状态名 = 上面 statuses 的 name，也是 UI 侧 config["events"] 的事件名。
            # 指令串用 %s 模板拼（别用 + 拼引号，容易把两头的引号写丢）
            # 回车提交这一条**不收编辑**（第二个参数 false）："点别处退出编辑"是给点击的规则，
            # 回车不该顺手结束编辑（提交链自己会 `UIInteract.end_edit`）；更要紧的是
            # 提前清掉 edit_ui 会让"提交派给正在编辑的输入框"落空（见 SystemManager.when_submit）。
            [QName.submit, QName.submit, 'PointerDetect.key("%s", false)' % QName.submit],
            [QName.pointer1_hold, QName.pointer1_hold, 'PointerDetect.key("%s")' % QName.pointer1_hold],
            [QName.pointer2_hold, QName.pointer2_hold, 'PointerDetect.key("%s")' % QName.pointer2_hold],
            # F3 开 / 关 FPS 显示（Config/UI/UIPreset_FPS.gd）：`toggle` = "开着就关、关着就开"，
            # 开 UI 只有 `UIInteract.open` 这一条路，toggle 只是替我们决定这次该 open 还是 close。
            [QName.key_f3, QName.key_f3, 'UIInteract.toggle(preset_name="FPS")'],
            # 常态右键菜单（点在空地上右键）：状态一满足就开那一扇 —— **独立 UI**（没有宿主、没有锚点），
            # 开在预设声明的指针处、点别处关。`content` 传"开菜单那一刻指针下的角色"（没有就是 null）：
            # 菜单第一项用它决定"打开谁的角色窗口 / 当前无角色"（见 UIPreset_Menu.char_option_text）。
            [QName.desktop_menu, QName.desktop_menu,
                'UIInteract.open(preset_name="DesktopMenu", content=PointerDetect.hover_char, close_on_blur=true)'],
            # "此格瓦片"窗口的**实时监控**（见 UIPreset_MapCell 里那个可选项）：启用了才走这条。
            # 状态一满足（= 启用 ∧ 指针动过）就按**鼠标所属格**刷新那个窗口——只改 x/y，窗口本身不动。
            [QName.map_monitor, QName.map_monitor,
                'UIInteract.open(preset_name="MapCell", cell=PointerDetect.map_position)'],
        ],
    },
    {
        "name": "时间周期",
        "statuses": [
            {"name": QName.tick, "time": [["Tick", "Advance"]],},
            {"name": QName.hour_advance, "time": [["Hour", "Advance"]],},
            {"name": QName.day_advance, "time": [["Day", "Advance"]],},
            {"name": QName.xun_advance, "time": [["Xun", "Advance"]],},
            {"name": QName.month_advance, "time": [["Month", "Advance"]],},
            {"name": QName.year_advance, "time": [["Year", "Advance"]],},            
        ],
    }
]
