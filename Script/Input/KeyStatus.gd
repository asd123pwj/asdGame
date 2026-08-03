class_name KeyStatus
extends RefCounted


# static var _keys: Array = [
#     KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
#     KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9,
#     KEY_KP_MULTIPLY, KEY_KP_DIVIDE, KEY_KP_SUBTRACT, KEY_KP_PERIOD, KEY_KP_ADD,
#     KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H, KEY_I, KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_Q, KEY_R, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z,
#     KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
#     KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_KP_ENTER, 
#     KEY_INSERT, KEY_DELETE, KEY_PAUSE, KEY_PRINT, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN,
#     KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN, 
#     KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK,
# ]
var isDown: bool
var isUp: bool
var isFirstDown: bool
var isFirstUp: bool

func _to_string() -> String:
    var str_ = " "
    if isDown:
        str_ += "Down "
    if isUp:
        str_ += "Up "
    if isFirstDown:
        str_ += "FirstDown "
    if isFirstUp:
        str_ += "FirstUp "
    return str_