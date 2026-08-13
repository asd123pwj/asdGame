class_name MsgHubSys
extends MsgBus


""" ---------- Basic ---------- """
static func _format_ID(type: String) -> String:
    return format_ID(["SYS", type])

static func _send(type: String, message: Variant) -> Enums.Code:
    return send(_format_ID(type), message)

static func _listen(type: String, callback: Callable) -> String:
    return listen(_format_ID(type), callback)

""" ---------- Command ---------- """
static func send_command(message: Variant) -> Enums.Code:
    return _send("COMMAND", message)

""" ---------- Spawn or Destory ---------- """
static func send_char_create(char_: Character) -> Enums.Code:
    return _send("CHAR_CREATE", char_)

static func send_spawn(char_: Character) -> Enums.Code:
    return _send("SPAWN", char_)

static func send_destory(char_: Character) -> Enums.Code:
    return _send("DESTORY", char_)


static func listen_char_create(callback: Callable) -> String:
    return _listen("CHAR_CREATE", callback)

static func listen_spawn(callback: Callable) -> String:
    return _listen("SPAWN", callback)

static func listen_destory(callback: Callable) -> String:
    return _listen("DESTORY", callback)