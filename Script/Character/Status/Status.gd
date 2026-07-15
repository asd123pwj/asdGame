class_name Status
extends RefCounted


var me: Character
var status_listeners: Dictionary[String, StatusType] = {}

func _init(me: Character, status_name: Array[String]) -> void:
    self.me = me
    add_status_listeners(status_name)


func check_enabled(status_name: String) -> bool:
    if not check_status_listener(status_name):
        return false
    return status_listeners[status_name].enabled

""" ---------- Listeners ---------- """
func add_status_listeners(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(add_status_listener(name))
    return codes

func add_status_listener(status_name: String) -> Enums.Code:
    if status_listeners.has(status_name):
        return Enums.Code.NOT_MODIFIED
    var lister: StatusType = StatusType.get_(status_name)
    status_listeners[status_name] = lister
    lister.listen(me)
    MsgHubChar.send_status_add(me, status_name)
    return Enums.Code.OK

func remove_status_listeners(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(remove_status_listener(name))
    return codes

func remove_status_listener(status_name: String) -> Enums.Code:
    if not status_listeners.has(status_name):
        return Enums.Code.NOT_MODIFIED
    status_listeners[status_name].unlisten(me)
    status_listeners.erase(status_name)
    MsgHubChar.send_status_remove(me, status_name)
    return Enums.Code.OK

func check_status_listener(status_name: String) -> bool:
    return status_listeners.has(status_name)
