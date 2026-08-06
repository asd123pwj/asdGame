class_name InputSys
extends RefCounted

static var mouse_position: Vector2 = Vector2.ZERO
static var on_edit: bool = false
static var keys_downing: Array[Variant] = []

func _init() -> void:
    pass

static func _input(event: InputEvent):
    @warning_ignore_start("unsafe_property_access")
    if event is InputEventKey:
        _send_key_status(event.keycode, event.pressed)
    elif event is InputEventMouseButton:
        _send_key_status(event.button_index, event.pressed)
    elif event is InputEventMouseMotion:
        mouse_position = event.position
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

static func _process(_delta: float) -> void:
    for key in keys_downing:
        MsgHubInput.send_key_down(key)

static func _send_key_status(key, isDown: bool):
    if isDown:
        if not key in keys_downing:
            keys_downing.append(key)
            MsgHubInput.send_key_first_down(key)
            # MsgHubInput.send_key_down(key)
    else:
        keys_downing.erase(key)
        MsgHubInput.send_key_first_up(key)
    