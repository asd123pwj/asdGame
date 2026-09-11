class_name SystemShortcutPreset_Input
extends ConfigBase
## 指针相关快捷：状态满足即执行 PointDetect 的执行函数（经指令系统调用）。
## 注：这些已改为内联写在 Config/Character/Archetype/Archetype_System.gd 中（只写一处），
## 此处保留作为参考，若在此恢复定义需同步移除内联版本，否则会重名报错。

var values: Array[Array] = [
    # ["Pointer Down", "Pointer Down", "PointDetect.pointer_down"],
    # ["Pointer Move", "Pointer Move", "PointDetect.pointer_move"],
    # ["Pointer Up", "Pointer Up", "PointDetect.pointer_up"],
    # ["Submit", "Submit", "PointDetect.submit"],
]
