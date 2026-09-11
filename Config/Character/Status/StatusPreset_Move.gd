class_name StatusPreset_Move
extends ConfigBase

var values: Array[Dictionary] = [
    
    {   
        "name": "On Left",
        "statuses": [["Right", "Unsatisfied"]],
    }, {   
        "name": "Shift + Left Click",
        "keys": [[[KEY_SHIFT, MOUSE_BUTTON_LEFT], Enums.KeyStatus.FIRST_UP]],
    },
]
