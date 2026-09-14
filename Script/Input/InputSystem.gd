class_name InputSys
extends BaseClass
## 输入系统：把引擎输入事件转成项目自己的消息（见 Script/Input/Input.md）。
## 本类只做"事件 → 消息"的转发，不做任何状态判定：按键状态由 Character 的 Status 判定，
## 指针命中由 PointerDetect 判定，UI 交互由 UIInteract 响应。
## 被谁用：Sys._input 把引擎事件转进来；PointerDetect / UIInteract / 各状态读这里的鼠标数据。

## 指针当前位置（屏幕坐标）。
## 被谁用：PointerDetect.update_targets（命中判定）、UiSystem._place（POINTER 策略开菜单）。
static var mouse_position: Vector2 = Vector2.ZERO
## 本帧累计的指针位移：一帧内多个 MouseMotion 事件相加，帧末由 end_frame() 清零。
## 消费方一律是"每帧调用一次"的（拖拽类指令），所以必须按帧对齐，否则：
##   指针停下后没有 MouseMotion 事件，旧位移会被每帧重复叠加 → 一直漂；
##   一帧内多个事件只用最后一个 → 快移时丢距离（跟不上光标）。
## "一帧"= Sys._process 覆盖的范围：_input 累计 → InputSys._process（按键类消费）
## → TimeSys._process（Tick 类消费，拖拽走这里）→ end_frame() 清零。
## 被谁用：UIInteract.drag。
static var mouse_delta: Vector2 = Vector2.ZERO
## 是否处于"编辑输入"模式（要录键位时置 true，避免输入的键被当成游戏按键）。
## 被谁用：需要录键位的界面/流程（如改绑快捷键）。
static var on_edit: bool = false
## 当前按住的键（键值，Godot 常量）。按住期间每帧发 HOLD，松开立刻移出。
## 被谁用：_input（维护）、_process（逐帧发 HOLD）、鼠标移动判断"是否在拖拽中"。
static var keys_holding: Array[Variant] = []

func _init() -> void:
    pass

## 引擎输入入口（由 Sys._input 转发）：键/鼠标键 → 按键消息；鼠标移动 → 累计位移。
## 只按住的键才发指针移动（单纯悬停不算拖拽）。
## 被谁用：Sys._input。
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

## 每帧给所有按住的键发一次 HOLD（逐帧状态就是靠它驱动的，如 "Mouse Left | Tick" 拖动）。
## 被谁用：Sys._process。
static func _process(_delta: float) -> void:
    for key in keys_holding:
        Msg.send_key_hold(key)


## 帧末结算：清空本帧累计的指针位移，供下一帧重新累计（指针不动则下一帧即 (0,0)，不会漂）。
## 必须在本帧所有消费方都跑完之后调用（由 Sys._process 最后调用）。
## 注意不能在 _process 里清零：拖拽是被 TimeSys._process 的 send_tick()（Tick 状态）触发的，
## 晚于本函数，早清零会让拖拽永远读到 (0,0)。
## 被谁用：Sys._process（末尾）。
static func end_frame() -> void:
    mouse_delta = Vector2.ZERO

## 按下 → 记进 keys_holding 并发 PRESS；松开 → 移出并发 RELEASE。
## 被谁用：_input。
static func _send_key_status(key, isDown: bool):
    if isDown:
        if not key in keys_holding:
            keys_holding.append(key)
            Msg.send_key_press(key)
    else:
        keys_holding.erase(key)
        Msg.send_key_release(key)
    
