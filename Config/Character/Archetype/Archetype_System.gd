class_name Archetype_System
extends ConfigBase
## 内联写法演示：statuses/shortcuts 等字段的元素既可是"已存在的预设名"(字符串)，
## 也可直接是"内联配置"(字典/列表)——内联则现场创建并注册，重名会报错。

var values: Array[Dictionary] = [
    {
        "name": "SYS",
        "packages": ["输入监控", "指针监控", "时间周期", "其它"],
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
            {"name": "Right", "match_any": true, "keys": [[KEY_RIGHT, Enums.KeyStatus.DOWN], [KEY_D, Enums.KeyStatus.DOWN]],}, 
            {"name": "Up", "match_any": true, "keys": [[KEY_UP, Enums.KeyStatus.DOWN], [KEY_W, Enums.KeyStatus.DOWN]],}, 
            {"name": "Left", "match_any": true, "keys": [[KEY_LEFT, Enums.KeyStatus.DOWN], [KEY_A, Enums.KeyStatus.DOWN]],}, 
            {"name": "Down", "match_any": true, "keys": [[KEY_DOWN, Enums.KeyStatus.DOWN], [KEY_S, Enums.KeyStatus.DOWN]],},
        ],
    },
    {
        "name": "指针监控",
        "statuses": [
            {"name": "Pointer Down", "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_DOWN]],}, 
            {"name": "Pointer Move", "keys": [[0, Enums.KeyStatus.POINTER_MOVE]],}, 
            {"name": "Pointer Up", "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_UP]],}, 
            {"name": "Submit", "keys": [[KEY_ENTER, Enums.KeyStatus.FIRST_DOWN]],},
        ],
        "shortcuts": [
            ["Pointer Down", "Pointer Down", "PointDetect.pointer_down"],
            ["Pointer Move", "Pointer Move", "PointDetect.pointer_move"],
            ["Pointer Up", "Pointer Up", "PointDetect.pointer_up"],
            ["Submit", "Submit", "PointDetect.submit"],
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
