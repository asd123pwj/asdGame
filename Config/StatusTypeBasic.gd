class_name StatusTypeBasic
extends ConfigBase

"""
name: String, 
auto_reset: bool, 
attr_type_listener_cfgs: Array[String]=[], 
attr_buff_listener_cfgs: Array[String]=[],
status_listener_cfgs: Array[String]=[]
"""

var values: Array[Array] = [
    ["Live", false, [["Health", ">", 0]]],
    ["Injured", true, [["Health", "changed"]]],
]