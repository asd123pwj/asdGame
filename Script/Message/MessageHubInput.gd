class_name MsgHubInput
extends MsgBus


""" ---------- Single Key Basic ---------- """
static func _format_ID(key: Variant, status: Enums.KeyStatus) -> String:
    if typeof(key) == TYPE_ARRAY:
        return format_ID(["Input", " ".join(key), str(status)])
    else:
        return format_ID(["Input", str(key), str(status)])

static func _send(key: Variant, status: Enums.KeyStatus) -> Enums.Code:
    return send(_format_ID(key, status), [key, status])

static func _listen(key: Variant, status: Enums.KeyStatus, callback: Callable) -> String:
    return listen(_format_ID(key, status), callback)

""" ---------- Single Key ---------- """
static func send_key_down(key: Variant) -> Enums.Code:
    return _send(key, Enums.KeyStatus.DOWN)

static func send_key_first_down(key: Variant) -> Enums.Code:
    return _send(key, Enums.KeyStatus.FIRST_DOWN)

# static func send_key_up(key: Variant) -> Enums.Code:
#     return _send(key, Enums.KeyStatus.UP)

static func send_key_first_up(key: Variant) -> Enums.Code:
    return _send(key, Enums.KeyStatus.FIRST_UP)

static func listen_key_down(key: Variant, callback: Callable) -> String:
    return _listen(key, Enums.KeyStatus.DOWN, callback)

static func listen_key_first_down(key: Variant, callback: Callable) -> String:
    return _listen(key, Enums.KeyStatus.FIRST_DOWN, callback)

# static func listen_key_up(key: Variant, callback: Callable) -> String:
#     return _listen(key, Enums.KeyStatus.UP, callback)

static func listen_key_first_up(key: Variant, callback: Callable) -> String:
    return _listen(key, Enums.KeyStatus.FIRST_UP, callback)

    




    
""" ---------- Combo Key ---------- """
# static func _format_keys(keys: Array) -> String:
#     return format_ID(["Input", " ".join(keys)])

# static func send_combo(keys: Array) -> Enums.Code:
#     return send(_format_keys(keys), keys)

# static func listen_combo(keys: Array, callback: Callable) -> String:
#     return listen(_format_keys(keys), callback)