class_name SystemShortcutPreset_Input
extends ConfigBase
## 指针相关快捷：状态满足即执行 PointDetect 的执行函数（经指令系统调用）。

var values: Array[Array] = [
    ["Mouse Left (First Down)", "Mouse Left (First Down)", "PointDetect.pointer_down"],
    ["Pointer Hold", "Pointer Hold", "PointDetect.pointer_move"],
    ["Mouse Left (Up)", "Mouse Left (Up)", "PointDetect.pointer_up"],
    ["Submit", "Submit", "PointDetect.submit"],
]
