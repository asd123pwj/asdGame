class_name StatusPreset_Basic
extends ConfigBase

"""
name: String, 
auto_reset: bool = false, 
match_any: bool = false,
attrs: Array[Array[ListenType]]=[]   
    [["name", "condition", value], ["name", "condition", value]]
    condition: AnyChanged, Changed, Within Limited, Over Limited, 
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
interactions: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    condition: Satisfied, Unsatisfied, Act
keys: Array[Array[ListenType]]=[]
    [[KEY_CODE, "condition"], [[KEY_CODE, KEY_CODE], "condition"]]
    condition: Enums.KeyStatus.HOLD, Enums.KeyStatus.PRESS, Enums.KeyStatus.RELEASE
time: Array[Array[ListenType]]=[]
    [["name", "condition"], ["name", "condition"]]
    name: Year, Month, Xun, Day, Hour
    condition: Advance

with_detect_transient: bool=false
with_detect_manual: bool=false
    为 true 时，需要 Msg.send_status_detected_transient / send_status_detected_manual 发消息来检测（瞬时 / 保持型两种），
"""

var values: Array[Dictionary] = [
    # {
    #     "name": "AlwaysSatisfied",
    # },
]
