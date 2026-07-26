class_name MsgHubChar
extends MsgBus


""" ---------- Basic ---------- """
static func _format_ID(char_: Character, type: String, type_name: String, action: String) -> String:
    return format_ID(["CHAR", str(char_.ID), type, type_name, action])

static func _send(char_: Character, type: String, type_name: String, action: String, message:Variant = null) -> Enums.Code:
    var node_ID = _format_ID(char_, type, type_name, action)
    if message != null:
        return send(node_ID, message)
    return send(node_ID, char_)

static func _listen(char_: Character, type: String, type_name: String, action: String, callback: Callable) -> String:
    var node_ID = _format_ID(char_, type, type_name, action)
    return listen(node_ID, callback)

static func _get_message(char_: Character, type: String, type_name: String, action: String) -> Variant:
    var node_ID = _format_ID(char_, type, type_name, action)
    return get_message(node_ID)


""" ---------- Attributes ---------- """
static func send_attr_changed(char_: Character, type_name: String) -> Enums.Code:
    return _send(char_, "ATTR", type_name, "changed")

static func listen_attr_changed(char_: Character, type_name: String, callback: Callable) -> String:
    return _listen(char_, "ATTR", type_name, "changed", callback)

""" ---------- Buff ---------- """
static func send_buff_add(char_: Character, buff_name: String) -> Enums.Code:
    return _send(char_, "BUFF", buff_name, "add")

static func send_buff_remove(char_: Character, buff_name: String) -> Enums.Code:
    return _send(char_, "BUFF", buff_name, "remove")

static func listen_buff_add(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen(char_, "BUFF", buff_name, "add", callback)

static func listen_buff_remove(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen(char_, "BUFF", buff_name, "remove", callback)

""" ---------- Character Statuses Listener ---------- """
static func send_status_satisfied(char_: Character, status_name: String) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "satisfied")

static func send_status_unsatisfied(char_: Character, status_name: String) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "unsatisfied")

static func send_status_add(char_: Character, status_name: String) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "add")

static func send_status_remove(char_: Character, status_name: String) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "remove")

## detect来传入目标，例如碰撞体接触，先detect发送接触目标以在消息节点记录，
## 再发送前面的send_status_enable令Touch状态为真，进而触发interaction，
## 而interaction内部用get_interaction_target去消息节点里面读取目标，
## 这样把target和status分开，不然不知道怎么target怎么告诉对应交互
static func send_status_detected(char_: Character, status_name: String, target: Variant) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "detected", target)

## 我觉得这玩意用不到
static func send_status_undetected(char_: Character, status_name: String, target: Variant) -> Enums.Code:
    return _send(char_, "STATUS", status_name, "undetected", target)

static func listen_status_satisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "satisfied", callback)

static func listen_status_unsatisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "unsatisfied", callback)

static func listen_status_add(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "add", callback)

static func listen_status_remove(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "remove", callback)

static func listen_status_detected(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "detected", callback)

## 我觉得这玩意用不到
static func listen_status_undetected(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "undetected", callback)

static func get_status_detected(char_: Character, interaction_name: String) -> Variant:
    return _get_message(char_, "STATUS", interaction_name, "detected")

## 我觉得这玩意用不到
static func get_status_undetected(char_: Character, interaction_name: String) -> Variant:
    return _get_message(char_, "STATUS", interaction_name, "undetected")

""" ---------- Character Behaviors ---------- """
static func send_behavior_add(char_: Character, behavior_name: String) -> Enums.Code:
    return _send(char_, "BEHAVIOR", behavior_name, "add")

static func send_behavior_remove(char_: Character, behavior_name: String) -> Enums.Code:
    return _send(char_, "BEHAVIOR", behavior_name, "remove")

static func send_behavior_act(char_: Character, behavior_name: String) -> Enums.Code:
    return _send(char_, "BEHAVIOR", behavior_name, "act")

static func listen_behavior_add(char_: Character, behavior_name: String, callback: Callable) -> String:
    return _listen(char_, "BEHAVIOR", behavior_name, "add", callback)

static func listen_behavior_remove(char_: Character, behavior_name: String, callback: Callable) -> String:
    return _listen(char_, "BEHAVIOR", behavior_name, "remove", callback)

static func listen_behavior_act(char_: Character, behavior_name: String, callback: Callable) -> String:
    return _listen(char_, "BEHAVIOR", behavior_name, "act", callback)

    
""" ---------- Character Interaction ---------- """
static func send_interaction_add(char_: Character, interaction_name: String) -> Enums.Code:
    return _send(char_, "INTERACTION", interaction_name, "add")

static func send_interaction_remove(char_: Character, interaction_name: String) -> Enums.Code:
    return _send(char_, "INTERACTION", interaction_name, "remove")
    
static func send_interaction_interact(char_: Character, interaction_name: String) -> Enums.Code:
    return _send(char_, "INTERACTION", interaction_name, "interact")
    
static func listen_interaction_add(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen(char_, "INTERACTION", interaction_name, "add", callback)

static func listen_interaction_remove(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen(char_, "INTERACTION", interaction_name, "remove", callback)

static func listen_interaction_interact(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen(char_, "INTERACTION", interaction_name, "interact", callback)
