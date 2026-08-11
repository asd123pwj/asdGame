class_name StatusBasic
extends ConfigBase

"""
name: String, 
auto_reset: bool = false, 
match_any: bool = false,
attrs: Array[Array[ListenType]]=[]   
    [["name", "condition", value], ["name", "condition", value]]
    condition: changed, not_modified, out_of_limited, >, >=, <, <=, ==, !=
buffs: Array[Array[ListenType]]=[],
    [["name", "condition"], ["name", "condition"]]
    condition: present, absent
statuses: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: satisfied, unsatisfied
behaviors: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: satisfied, unsatisfied, act
keys: Array[Array[ListenType]]=[]
    [[KEY_CODE, "condition"], [KEY_CODE, "condition"]]
    condition: down, first down, first up
combos: Array[Array[ListenType]]=[]
    [[[KEY_CODE, KEY_CODE]], [[KEY_CODE, KEY_CODE]]]
with_detect: bool=false
    为true时，需要send_status_detected发送信号来检测，
"""

var values: Array[Dictionary] = [
    {
        "name": "Healable" # 仅name时默认为true，可以作为标识符，用satisfied检测标识
    },
    {
        "name": "Detect=>Healable",
        "auto_reset": true,
        "with_detect": true,
    },
    {   
        "name": "Detect=>CostHeal",
        "auto_reset": true,
        "with_detect": true,
    },
    {   
        "name": "Detect=>Edible",
        "auto_reset": true,
        "with_detect": true,
    },
    {
        "name": "Dead",
        "attrs": [["Health", "over_limit"]],
    }, {
        "name": "Live",
        "statuses": [["Dead", "unsatisfied"]],
    }, {
        "name": "Injured",
        "auto_reset": true,
        "attrs": [["Health", "changed"]],
    }, {
        "name": "Rebirth",
        "auto_reset": true,
        "behaviors": [["Rebirth", "act"]],
    }, {   
        "name": "Detect=>Touch",
        "auto_reset": true,
        "with_detect": true,
    }, {   
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
        "statuses": [["Right", "unsatisfied"]],
    }, {   
        "name": "Shift + Left Click",
        "keys": [[[KEY_SHIFT, MOUSE_BUTTON_LEFT], Enums.KeyStatus.FIRST_UP]],
    },
]
