class_name InputSys
extends BaseClass

static var mouse_position: Vector2 = Vector2.ZERO
static var mouse_delta: Vector2 = Vector2.ZERO   # 相对上次鼠标事件的移动距离
static var on_edit: bool = false
static var keys_holding: Array[Variant] = []

func _init() -> void:
    pass

static func _input(event: InputEvent):
    @warning_ignore_start("unsafe_property_access")
    if event is InputEventKey:
        _send_key_status(event.keycode, event.pressed)
    elif event is InputEventMouseButton:
        _send_key_status(event.button_index, event.pressed)
    elif event is InputEventMouseMotion:
        mouse_delta = event.position - mouse_position
        mouse_position = event.position
        Msg.send_pointer_move()
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

static func _process(_delta: float) -> void:
    for key in keys_holding:
        Msg.send_key_hold(key)

static func _send_key_status(key, isDown: bool):
    if isDown:
        if not key in keys_holding:
            keys_holding.append(key)
            Msg.send_key_press(key)
    else:
        keys_holding.erase(key)
        Msg.send_key_release(key)
    