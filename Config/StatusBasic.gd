class_name StatusBasic
extends ConfigBase

"""
name: String, 
auto_reset: bool = false, 
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
        "keys": [[KEY_RIGHT, "first down"]],
    }, {   
        "name": "Up",
        "keys": [[KEY_UP, "first up"]],
    }, {   
        "name": "Left",
        "keys": [[KEY_LEFT, "down"]],
    }, {   
        "name": "On Left",
        "statuses": [["Right", "unsatisfied"]],
    },
]
