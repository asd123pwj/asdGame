class_name StatusPreset_Basic
extends ConfigBase

"""
name: String, 
auto_reset: bool = false, 
match_any: bool = false,
attrs: Array[Array[ListenType]]=[]   
    [["name", "condition", value], ["name", "condition", value]]
    condition: Changed, Within Limited, Over Limited, 
    #  >,        >=,        <,        <=,        ==,        !=
    # ">Base",  ">=Base",  "<Base",  "<=Base",  "==Base",  "!=Base",
    # ">Base+", ">=Base+", "<Base+", "<=Base+", "==Base+", "!=Base+",
    # ">Base-", ">=Base-", "<Base-", "<=Base-", "==Base-", "!=Base-",
    # ">Base*", ">=Base*", "<Base*", "<=Base*", "==Base*", "!=Base*",
    # ">Base/", ">=Base/", "<Base/", "<=Base/", "==Base/", "!=Base/",
buffs: Array[Array[ListenType]]=[],
    [["name", "condition"], ["name", "condition"]]
    condition: Present, Absent
statuses: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: Satisfied, Unsatisfied
behaviors: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: Satisfied, Unsatisfied, Act
keys: Array[Array[ListenType]]=[]
    [[KEY_CODE, "condition"], [[KEY_CODE, KEY_CODE], "condition"]]
    condition: Enums.KeyStatus.DOWN, Enums.KeyStatus.FIRST_DOWN, Enums.KeyStatus.FIRST_UP
time: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    name: Year, Month, Xun, Day, Hour
    condition: Advance

with_detect: bool=false
    为true时，需要send_status_detected发送信号来检测，
"""

var values: Array[Dictionary] = [
]
