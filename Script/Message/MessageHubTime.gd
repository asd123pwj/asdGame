class_name MsgHubTime
extends MsgBus


""" ---------- Basic ---------- """
static func _format_ID(type: String) -> String:
    return format_ID(["TIME", type])

static func _send(type: String, message: Variant) -> Enums.Code:
    return send(_format_ID(type), message)

static func _listen(type: String, callback: Callable) -> String:
    return listen(_format_ID(type), callback)

""" ---------- ADVANCE ---------- """
static func send_advance_year(message: Variant) -> Enums.Code:
    return _send("ADVANCE_YEAR", message)

static func send_advance_month(message: Variant) -> Enums.Code:
    return _send("ADVANCE_MONTH", message)

static func send_advance_xun(message: Variant) -> Enums.Code:
    return _send("ADVANCE_XUN", message)

static func send_advance_day(message: Variant) -> Enums.Code:
    return _send("ADVANCE_DAY", message)

static func send_advance_hour(message: Variant) -> Enums.Code:
    return _send("ADVANCE_HOUR", message)

# static func send_advance(message: Variant) -> Enums.Code:
#     return _send("ADVANCE", message)

static func listen_advance_year(callback: Callable) -> String:
    return _listen("ADVANCE_YEAR", callback)

static func listen_advance_month(callback: Callable) -> String:
    return _listen("ADVANCE_MONTH", callback)

static func listen_advance_xun(callback: Callable) -> String:
    return _listen("ADVANCE_XUN", callback)

static func listen_advance_day(callback: Callable) -> String:
    return _listen("ADVANCE_DAY", callback)

static func listen_advance_hour(callback: Callable) -> String:
    return _listen("ADVANCE_HOUR", callback)

# static func listen_advance(callback: Callable) -> String:
#     return _listen("ADVANCE", callback)