class_name Archetype_System
extends ConfigBase

var values: Array[Dictionary] = [
    {
        "name": "SYS",
        "packages": ["输入监控", "指针监控", "时间周期"],
    },
    {
        "name": "输入监控",
        "statuses": ["Right", "Up", "Left", "Down"],
    },
    {
        "name": "指针监控",
        "statuses": ["Pointer Down", "Pointer Hold", "Pointer Up", "Submit"],
        "shortcuts": ["Pointer Down", "Pointer Hold", "Pointer Up", "Submit"],
    },
    {
        "name": "时间周期",
        "statuses": ["Tick", "Hour Advance", "Day Advance", "Xun Advance", "Month Advance", "Year Advance"],
    }
]
