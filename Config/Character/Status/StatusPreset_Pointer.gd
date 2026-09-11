class_name StatusPreset_Pointer
extends ConfigBase
## 指针/交互键的状态：把按键事件翻译成状态，供 SystemShortcut 声明"状态满足→执行指令"。

var values: Array[Dictionary] = [
    {
        "name": "Pointer Down",
        "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_DOWN]],
    }, {
        "name": "Pointer Hold",
        "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.DOWN]],
    }, {
        "name": "Pointer Up",
        "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_UP]],
    }, {
        "name": "Submit",
        "keys": [[KEY_ENTER, Enums.KeyStatus.FIRST_DOWN]],
    },
]
