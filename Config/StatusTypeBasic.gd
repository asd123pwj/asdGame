class_name StatusTypeBasic
extends ConfigBase

"""
name: String, 
auto_reset: bool, 
attr_type_listener_cfgs: Array[Array[ListenType]]=[]   
    [["name", "condition", value], ["name", "condition", value]]
    condition: present, absent, changed, >, >=, <, <=, ==, !=
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
    ["Live", false, [["Health", ">", 0]]],
    ["Injured", true, [["Health", "changed"]]],
    ["Dead", false, [], [], [["Live", "unsatisfied"]]],
    ["Rebirth", true, [], [], [], [["Rebirth", "act"]]],
    ["Touch", true, [], [], [], [], true]
]