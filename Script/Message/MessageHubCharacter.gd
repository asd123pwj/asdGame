class_name MsgHubChar
extends RefCounted


""" ---------- Basic ---------- """
static func _format_ID(char_: Character, type: String, type_name: String, action: String) -> String:
    return MsgBus.format_ID(["CHAR", str(char_.ID), type, type_name, action])

static func _send(char_: Character, type: String, type_name: String, action: String) -> void:
    var node_ID = _format_ID(char_, type, type_name, action)
    MsgBus.send(node_ID, "")

static func _listen(char_: Character, type: String, type_name: String, action: String, callback: Callable) -> void:
    var node_ID = _format_ID(char_, type, type_name, action)
    MsgBus.listen(node_ID, callback)


""" ---------- Attribute Type ---------- """
static func send_type_add(char_: Character, type_name: String) -> void:
    _send(char_, "TYPE", type_name, "add")
    
static func send_type_remove(char_: Character, type_name: String) -> void:
    _send(char_, "TYPE", type_name, "remove")

static func send_type_change(char_: Character, type_name: String) -> void:
    _send(char_, "TYPE", type_name, "change")

static func listen_type_add(char_: Character, type_name: String, callback: Callable) -> void:
    _listen(char_, "TYPE", type_name, "add", callback)

static func listen_type_remove(char_: Character, type_name: String, callback: Callable) -> void:
    _listen(char_, "TYPE", type_name, "remove", callback)

static func listen_type_change(char_: Character, type_name: String, callback: Callable) -> void:
    _listen(char_, "TYPE", type_name, "change", callback)

    
""" ---------- Attribute Buff ---------- """
static func send_buff_add(char_: Character, buff_name: String) -> void:
    _send(char_, "BUFF", buff_name, "add")

static func send_buff_remove(char_: Character, buff_name: String) -> void:
    _send(char_, "BUFF", buff_name, "remove")

static func listen_buff_add(char_: Character, buff_name: String, callback: Callable) -> void:
    _listen(char_, "BUFF", buff_name, "add", callback)

static func listen_buff_remove(char_: Character, buff_name: String, callback: Callable) -> void:
    _listen(char_, "BUFF", buff_name, "remove", callback)
