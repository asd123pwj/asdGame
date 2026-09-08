# class_name Msg
# extends MsgBus


# """ ---------- Basic ---------- """
# static func _format_time(type: String) -> String:
#     return format_ID(["TIME", type])

# static func _send_time(type: String, message: Variant) -> Array:
#     return send(_format_time(type), message)

# static func _listen_time(type: String, callback: Callable) -> String:
#     return listen(_format_time(type), callback)

# """ ---------- ADVANCE ---------- """
# static func send_tick(message: Variant = null) -> Array:
#     return _send_time("TICK", message)

# static func listen_tick(callback: Callable) -> String:
#     return _listen_time("TICK", callback)

# """ ---------- ADVANCE ---------- """
# static func send_advance_year(message: Variant) -> Array:
#     return _send_time("ADVANCE_YEAR", message)

# static func send_advance_month(message: Variant) -> Array:
#     return _send_time("ADVANCE_MONTH", message)

# static func send_advance_xun(message: Variant) -> Array:
#     return _send_time("ADVANCE_XUN", message)

# static func send_advance_day(message: Variant) -> Array:
#     return _send_time("ADVANCE_DAY", message)

# static func send_advance_hour(message: Variant) -> Array:
#     return _send_time("ADVANCE_HOUR", message)

# # static func send_advance(message: Variant) -> Array:
# #     return _send_time("ADVANCE", message)

# static func listen_advance_year(callback: Callable) -> String:
#     return _listen_time("ADVANCE_YEAR", callback)

# static func listen_advance_month(callback: Callable) -> String:
#     return _listen_time("ADVANCE_MONTH", callback)

# static func listen_advance_xun(callback: Callable) -> String:
#     return _listen_time("ADVANCE_XUN", callback)

# static func listen_advance_day(callback: Callable) -> String:
#     return _listen_time("ADVANCE_DAY", callback)

# static func listen_advance_hour(callback: Callable) -> String:
#     return _listen_time("ADVANCE_HOUR", callback)

# # static func listen_advance(callback: Callable) -> String:
# #     return _listen_time("ADVANCE", callback)