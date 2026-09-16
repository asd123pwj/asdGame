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
            {"name": QName.pointer_move, "keys": [[MOUSE_BUTTON_NONE, Enums.KeyStatus.POINTER_MOVE]],},
            # 一个鼠标键三个状态：按下 / 按住 / 松开
            {"name": QName.mouseLeft_press, "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.PRESS]],},
            {"name": QName.mouseLeft_hold, "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.HOLD]],},
            {"name": QName.mouseLeft_release, "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.RELEASE]],},
            {"name": QName.mouseRight_hold, "keys": [[MOUSE_BUTTON_RIGHT, Enums.KeyStatus.HOLD]],},
            
            {"name": QName.right, "match_any": true, "keys": [[KEY_RIGHT, Enums.KeyStatus.HOLD], [KEY_D, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.up, "match_any": true, "keys": [[KEY_UP, Enums.KeyStatus.HOLD], [KEY_W, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.left, "match_any": true, "keys": [[KEY_LEFT, Enums.KeyStatus.HOLD], [KEY_A, Enums.KeyStatus.HOLD]],}, 
            {"name": QName.down, "match_any": true, "keys": [[KEY_DOWN, Enums.KeyStatus.HOLD], [KEY_S, Enums.KeyStatus.HOLD]],},
            {"name": QName.submit, "match_any": true, "keys": [[KEY_ENTER, Enums.KeyStatus.PRESS], [KEY_KP_ENTER, Enums.KeyStatus.PRESS]],},
        
        ],
    },
    {
        "name": "指针交互",
        "shortcuts": [
            # 每帧刷新指针目标（hover 变化时发 enter/exit），菜单 hover 展开依赖它
            ["Pointer Refresh", QName.tick, "PointerDetect.update_targets"],
            # 每帧跑一遍 AutoSys 的登记（状态满足期间要一直做的事，如等比缩放；不看指针在哪）
            ["Auto Tick", QName.tick, "AutoSys.update"],
            # 统一入口 PointerDetect.key <状态名>：状态名 = 上面 statuses 的 name，也是 UI 侧 config["events"] 的事件名
            ["Pointer Move", QName.pointer_move, "PointerDetect.key \"" + QName.pointer_move + "\""],
            ["Submit", QName.submit, "PointerDetect.key \"" + QName.submit + "\""],
            ["Mouse Left Press", QName.mouseLeft_press, "PointerDetect.key \"" + QName.mouseLeft_press + "\""],
            ["Mouse Left Hold", QName.mouseLeft_hold, "PointerDetect.key \"" + QName.mouseLeft_hold + "\""],
            ["Mouse Left Release", QName.mouseLeft_release, "PointerDetect.key \"" + QName.mouseLeft_release + "\""],
            ["Mouse Right Hold", QName.mouseRight_hold, "PointerDetect.key \"" + QName.mouseRight_hold + "\""],
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
