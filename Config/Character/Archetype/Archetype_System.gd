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
            # 测试用：J / K 开关两个测试 UI（见 Config/UI/UIPreset_Test.gd）
            # 用 PRESS 而不是 HOLD：HOLD 每帧都满足（开关会被按帧反复切），PRESS 只在按下的那一下满足
            {"name": QName.key_j, "keys": [[KEY_J, Enums.KeyStatus.PRESS]],},
            {"name": QName.key_k, "keys": [[KEY_K, Enums.KeyStatus.PRESS]],},
        
        ],
    },
    {
        "name": "指针交互",
        "shortcuts": [
            # 每帧刷新指针目标（hover 变化时发 enter/exit），菜单 hover 展开依赖它：
            # 已挪进 InputSys._process（在派发按键之前，一帧只检测这一次），不再占一条 Tick 快捷
            # ["Pointer Refresh", QName.tick, "PointerDetect._process"],
            # 统一入口 PointerDetect.key("状态名")：状态名 = 上面 statuses 的 name，也是 UI 侧 config["events"] 的事件名。
            # 指令串用 %s 模板拼（别用 + 拼引号，容易把两头的引号写丢）
            # 回车提交这一条**不收编辑**（第二个参数 false）："点别处退出编辑"是给点击的规则，
            # 回车不该顺手结束编辑（提交链自己会 `UIInteract.end_edit`）；更要紧的是
            # 提前清掉 edit_ui 会让"提交派给正在编辑的输入框"落空（见 SystemManager.when_submit）。
            [QName.submit, QName.submit, 'PointerDetect.key("%s", false)' % QName.submit],
            [QName.pointer1_hold, QName.pointer1_hold, 'PointerDetect.key("%s")' % QName.pointer1_hold],
            [QName.pointer2_hold, QName.pointer2_hold, 'PointerDetect.key("%s")' % QName.pointer2_hold],
            # 测试用：J / K 开关两个测试 UI（独立 UI，只给预设名；toggle = 显示着就关、否则开）
            [QName.key_j, QName.key_j, 'UIInteract.toggle(preset_name="TestShow")'],
            [QName.key_k, QName.key_k, 'UIInteract.toggle(preset_name="TestInput")'],
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
