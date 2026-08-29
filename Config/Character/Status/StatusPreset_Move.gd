class_name StatusPreset_Move
extends ConfigBase

var values: Array[Dictionary] = [
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
        "name": "On Left",
        "statuses": [["Right", "Unsatisfied"]],
    }, {   
        "name": "Shift + Left Click",
        "keys": [[[KEY_SHIFT, MOUSE_BUTTON_LEFT], Enums.KeyStatus.FIRST_UP]],
    },
]
