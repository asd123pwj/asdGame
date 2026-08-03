class_name InputSys
extends RefCounted

## 注意鼠标按键的isFirstXXX与isXXX始终相等，因为鼠标按键长按不会重复触发
static var keys_status: Dictionary[Variant, KeyStatus] = {}
static var mouse_position: Vector2 = Vector2.ZERO

static func _input(event: InputEvent):
    @warning_ignore_start("unsafe_property_access")
    if event is InputEventKey:
        _set_key_status(event.keycode, event.pressed)
        # print(event.keycode, keys_status[event.keycode])
    elif event is InputEventMouseButton:
        _set_key_status(event.button_index, event.pressed)
        # print(event.button_index, keys_status[event.button_index])
    elif event is InputEventMouseMotion:
        mouse_position = event.position
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

    
static func _set_key_status(key, isDown: bool):
    var key_status = Utils.get_or_set_dict(keys_status, [key], KeyStatus.new())
    if isDown:
        key_status.isFirstDown = !key_status.isDown
        key_status.isFirstUp = false
        key_status.isDown = true
        key_status.isUp = false
    else:
        key_status.isFirstDown = false
        key_status.isFirstUp = !key_status.isUp
        key_status.isDown = false
        key_status.isUp = true
