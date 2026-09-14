class_name Archetype_System
extends ConfigBase
## 内联写法演示：statuses/shortcuts 等字段的元素既可是"已存在的预设名"(字符串)，
## 也可直接是"内联配置"(字典/列表)——内联则现场创建并注册，重名会报错。

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
            {"name": "Pointer Move", "keys": [[MOUSE_BUTTON_NONE, Enums.KeyStatus.POINTER_MOVE]],},
            {"name": "Mouse Left", "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.HOLD]],},
            {"name": "Mouse Left | Tick", "statuses": [["Mouse Left", "Satisfied"], ["Tick", "Satisfied"]]},
            {"name": "Mouse Right", "keys": [[MOUSE_BUTTON_RIGHT, Enums.KeyStatus.HOLD]],},
            
            {"name": "Right", "match_any": true, "keys": [[KEY_RIGHT, Enums.KeyStatus.HOLD], [KEY_D, Enums.KeyStatus.HOLD]],}, 
            {"name": "Up", "match_any": true, "keys": [[KEY_UP, Enums.KeyStatus.HOLD], [KEY_W, Enums.KeyStatus.HOLD]],}, 
            {"name": "Left", "match_any": true, "keys": [[KEY_LEFT, Enums.KeyStatus.HOLD], [KEY_A, Enums.KeyStatus.HOLD]],}, 
            {"name": "Down", "match_any": true, "keys": [[KEY_DOWN, Enums.KeyStatus.HOLD], [KEY_S, Enums.KeyStatus.HOLD]],},
            {"name": "Submit", "match_any": true, "keys": [[KEY_ENTER, Enums.KeyStatus.PRESS], [KEY_KP_ENTER, Enums.KeyStatus.PRESS]],},
        
        ],
    },
    {
        "name": "指针交互",
        "shortcuts": [
            # 每帧刷新指针目标（hover 变化时发 enter/exit），菜单 hover 展开依赖它
            ["Pointer Refresh", "Tick", "PointerDetect.update_targets"],
            # 统一入口 PointerDetect.key <状态名>：状态名 = 上面 statuses 的 name，也是 UI 侧 config["events"] 的事件名
            ["Pointer Move", "Pointer Move", "PointerDetect.key \"Pointer Move\""],
            ["Submit", "Submit", "PointerDetect.key \"Submit\""],
            ["Mouse Left", "Mouse Left", "PointerDetect.key \"Mouse Left\""],
            ["Mouse Left | Tick", "Mouse Left | Tick", "PointerDetect.key \"Mouse Left | Tick\""],
            ["Mouse Right", "Mouse Right", "PointerDetect.key \"Mouse Right\""],
        ],
    },
    {
        "name": "时间周期",
        "statuses": [
            {"name": "Tick", "time": [["Tick", "Advance"]],},
            {"name": "Hour Advance", "time": [["Hour", "Advance"]],},
            {"name": "Day Advance", "time": [["Day", "Advance"]],},
            {"name": "Xun Advance", "time": [["Xun", "Advance"]],},
            {"name": "Month Advance", "time": [["Month", "Advance"]],},
            {"name": "Year Advance", "time": [["Year", "Advance"]],},            
        ],
    }
]
