class_name MsgHubCmd
extends MsgBus


static func send_cmd(message: Variant) -> Enums.Code:
    return super.send("COMMAND", message)

static func listen_cmd(callback: Callable) -> String:
    return super.listen("COMMAND", callback)
