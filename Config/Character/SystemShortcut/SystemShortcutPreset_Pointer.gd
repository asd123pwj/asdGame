class_name SystemShortcutPreset_Pointer
extends ConfigBase
## 指针相关快捷：状态满足即执行 PointDetect 的执行函数（经指令系统调用）。

var values: Array[Array] = [
    ["Pointer Down", "Pointer Down", "PointDetect.pointer_down"],
    ["Pointer Hold", "Pointer Hold", "PointDetect.pointer_move"],
    ["Pointer Up", "Pointer Up", "PointDetect.pointer_up"],
    ["Submit", "Submit", "PointDetect.submit"],
]
