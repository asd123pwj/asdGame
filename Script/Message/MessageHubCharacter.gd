class_name MsgHubChar
extends MsgBus


""" ---------- Basic ---------- """
static func _format_ID(char_: Character, type: String, type_name: String, action: String) -> String:
    return format_ID(["CHAR", str(char_.ID), type, type_name, action])

static func _send(char_: Character, type: String, type_name: String, action: String, message = "") -> Enums.Code:
    var node_ID = _format_ID(char_, type, type_name, action)
    return send(node_ID, message)

static func _listen(char_: Character, type: String, type_name: String, action: String, callback: Callable) -> String:
    var node_ID = _format_ID(char_, type, type_name, action)
    return listen(node_ID, callback)


""" ---------- Attribute Type ---------- """
static func send_type_add(char_: Character, type_name: String, message = "") -> Enums.Code:
    return _send(char_, "TYPE", type_name, "add", message)
    
static func send_type_remove(char_: Character, type_name: String, message = "") -> Enums.Code:
    return _send(char_, "TYPE", type_name, "remove", message)

static func send_type_changed(char_: Character, type_name: String, message = "") -> Enums.Code:
    return _send(char_, "TYPE", type_name, "change", message)

static func listen_type_add(char_: Character, type_name: String, callback: Callable) -> String:
    return _listen(char_, "TYPE", type_name, "add", callback)

static func listen_type_remove(char_: Character, type_name: String, callback: Callable) -> String:
    return _listen(char_, "TYPE", type_name, "remove", callback)

static func listen_type_changed(char_: Character, type_name: String, callback: Callable) -> String:
    return _listen(char_, "TYPE", type_name, "change", callback)

    
""" ---------- Attribute Buff ---------- """
static func send_buff_add(char_: Character, buff_name: String, message = "") -> Enums.Code:
    return _send(char_, "BUFF", buff_name, "add", message)

static func send_buff_remove(char_: Character, buff_name: String, message = "") -> Enums.Code:
    return _send(char_, "BUFF", buff_name, "remove", message)

static func listen_buff_add(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen(char_, "BUFF", buff_name, "add", callback)

static func listen_buff_remove(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen(char_, "BUFF", buff_name, "remove", callback)

""" ---------- Character Status Listener ---------- """
static func send_status_satisfied(char_: Character, status_name: String, message = "") -> Enums.Code:
    return _send(char_, "STATUS", status_name, "satisfied", message)

static func send_status_unsatisfied(char_: Character, status_name: String, message = "") -> Enums.Code:
    return _send(char_, "STATUS", status_name, "unsatisfied", message)

static func send_status_add(char_: Character, status_name: String, message = "") -> Enums.Code:
    return _send(char_, "STATUS", status_name, "add", message)

static func send_status_remove(char_: Character, status_name: String, message = "") -> Enums.Code:
    return _send(char_, "STATUS", status_name, "remove", message)

static func listen_status_satisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "satisfied", callback)

static func listen_status_unsatisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "unsatisfied", callback)

static func listen_status_add(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "add", callback)

static func listen_status_remove(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen(char_, "STATUS", status_name, "remove", callback)

