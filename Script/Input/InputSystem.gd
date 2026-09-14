class_name InputSys
extends BaseClass

static var mouse_position: Vector2 = Vector2.ZERO
## 本帧累计的指针位移：一帧内多个 MouseMotion 事件相加，帧末由 end_frame() 清零。
## 消费方一律是"每帧调用一次"的（拖拽类指令），所以必须按帧对齐，否则：
##   指针停下后没有 MouseMotion 事件，旧位移会被每帧重复叠加 → 一直漂；
##   一帧内多个事件只用最后一个 → 快移时丢距离（跟不上光标）。
## "一帧"= Sys._process 覆盖的范围：_input 累计 → InputSys._process（按键类消费）
## → TimeSys._process（Tick 类消费，拖拽走这里）→ end_frame() 清零。
static var mouse_delta: Vector2 = Vector2.ZERO
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
        mouse_delta += event.position - mouse_position
        mouse_position = event.position
        # 只有按住某键时才算"拖拽中的移动"（单纯悬停不该触发 Pointer Move 状态/拖拽类指令）
        if not keys_holding.is_empty():
            Msg.send_pointer_move()
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

static func _process(_delta: float) -> void:
    for key in keys_holding:
        Msg.send_key_hold(key)


## 帧末结算：清空本帧累计的指针位移，供下一帧重新累计（指针不动则下一帧即 (0,0)，不会漂）。
## 必须在本帧所有消费方都跑完之后调用（由 Sys._process 最后调用）。
## 注意不能在 _process 里清零：拖拽是被 TimeSys._process 的 send_tick()（Tick 状态）触发的，
## 晚于本函数，早清零会让拖拽永远读到 (0,0)。
static func end_frame() -> void:
    mouse_delta = Vector2.ZERO

static func _send_key_status(key, isDown: bool):
    if isDown:
        if not key in keys_holding:
            keys_holding.append(key)
            Msg.send_key_press(key)
    else:
        keys_holding.erase(key)
        Msg.send_key_release(key)
    