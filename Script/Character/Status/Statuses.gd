class_name Statuses
extends RefCounted


var me: Character
var statuses: Dictionary[String, Status] = {}

func _init(me: Character, status_name: Array[String]) -> void:
    self.me = me
    add_statuses(status_name)


func check_satisfied(status_name: String) -> bool:
    if not check_status(status_name):
        return false
    return statuses[status_name].satisfied[me]

""" ---------- Listeners ---------- """
func add_statuses(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(add_status(name))
    return codes

func add_status(status_name: String) -> Enums.Code:
    if statuses.has(status_name):
        return Enums.Code.NOT_MODIFIED
    var status: Status = Status.get_(status_name)
    statuses[status_name] = status
    status.listen(me)
    MsgHubChar.send_status_add(me, status_name)
    return Enums.Code.OK

func remove_statuses(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(remove_status(name))
    return codes

func remove_status(status_name: String) -> Enums.Code:
    if not statuses.has(status_name):
        return Enums.Code.NOT_MODIFIED
    statuses[status_name].unlisten(me)
    statuses.erase(status_name)
    MsgHubChar.send_status_remove(me, status_name)
    return Enums.Code.OK

func check_status(status_name: String) -> bool:
    return statuses.has(status_name)
