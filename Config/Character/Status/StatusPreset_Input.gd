class_name StatusPreset_Input
extends ConfigBase
## 指针/交互键的状态：把按键事件翻译成状态，供 SystemShortcut 声明"状态满足→执行指令"。

var values: Array[Dictionary] = [
    {
        "name": "Mouse Left (First Down)",
        "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_DOWN]],
    }, {
        "name": "Pointer Move",
        "keys": [[0, Enums.KeyStatus.POINTER_MOVE]],
    }, {
        "name": "Mouse Left (Up)",
        "keys": [[MOUSE_BUTTON_LEFT, Enums.KeyStatus.FIRST_UP]],
    }, 
    
    
    {   
        "name": "Right", "match_any": true,
        "keys": [[KEY_RIGHT, Enums.KeyStatus.DOWN], [KEY_D, Enums.KeyStatus.DOWN]],
    }, {   
        "name": "Up", "match_any": true,
        "keys": [[KEY_UP, Enums.KeyStatus.DOWN], [KEY_W, Enums.KeyStatus.DOWN]],
    }, {   
        "name": "Left", "match_any": true,
        "keys": [[KEY_LEFT, Enums.KeyStatus.DOWN], [KEY_A, Enums.KeyStatus.DOWN]],
    },  {   
        "name": "Down", "match_any": true,
        "keys": [[KEY_DOWN, Enums.KeyStatus.DOWN], [KEY_S, Enums.KeyStatus.DOWN]],
    }, 
    
    {
        "name": "Submit",
        "keys": [[KEY_ENTER, Enums.KeyStatus.FIRST_DOWN]],
    },
]
