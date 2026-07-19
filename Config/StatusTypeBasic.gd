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
"""

var values: Array[Array] = [
    ["Live", false, [["Health", ">", 0]]],
    ["Injured", true, [["Health", "changed"]]],
    ["Dead", false, [], [], [["Live", "unsatisfied"]]]
]