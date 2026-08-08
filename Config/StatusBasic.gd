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
        "name": "Touch",
        "auto_reset": true,
        "with_detect": true,
    }, {   
        "name": "Right",
        "keys": [[KEY_RIGHT, Enums.KeyStatus.DOWN]],
    }, {   
        "name": "Up",
        "keys": [[KEY_UP, Enums.KeyStatus.FIRST_UP]],
    }, {   
        "name": "Left", "match_any": true,
        "keys": [[KEY_LEFT, Enums.KeyStatus.DOWN], [KEY_A, Enums.KeyStatus.DOWN]],
    }, {   
        "name": "On Left",
        "statuses": [["Right", "unsatisfied"]],
    }, {   
        "name": "Shift + Left Click",
        "keys": [[[KEY_SHIFT, MOUSE_BUTTON_LEFT], Enums.KeyStatus.FIRST_UP]],
    },
]
