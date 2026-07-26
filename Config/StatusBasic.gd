class_name StatusBasic
extends ConfigBase

"""
name: String, 
auto_reset: bool, 
attr_type_listener_cfgs: Array[Array[ListenType]]=[]   
    [["name", "condition", value], ["name", "condition", value]]
    condition: changed, not_modified, out_of_limited, >, >=, <, <=, ==, !=
attr_buff_listener_cfgs: Array[Array[ListenType]]=[],
    [["name", "condition"], ["name", "condition"]]
    condition: present, absent
status_listener_cfgs: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: satisfied, unsatisfied
behavior_listener_cfgs: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: satisfied, unsatisfied, act
with_detect: bool=false
    为true时，需要send_status_detected发送信号来检测，
"""

var values: Array[Array] = [
    ["Dead", false, [["Health", "over_limit"]], [], []],
    ["Live", false, [], [], [["Dead", "unsatisfied"]]],
    ["Injured", true, [["Health", "changed"]]],
    ["Rebirth", true, [], [], [], [["Rebirth", "act"]]],
    ["Touch", true, [], [], [], [], true]
]