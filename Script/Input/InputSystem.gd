class_name InputSys
extends BaseClass
## 输入系统：把引擎输入事件转成项目自己的消息（见 Script/Input/Input.md）。
## 本类只做"事件 → 消息"的转发，不做任何状态判定：按键状态由 Character 的 Status 判定，
## 指针命中由 PointerDetect 判定，UI 交互由 UIInteract 响应。
## 被谁用：Sys._input 把引擎事件转进来；PointerDetect / UIInteract / 各状态读这里的鼠标数据。

## 指针当前位置（屏幕坐标）。
## 被谁用：PointerDetect._process（命中判定）、UIInteract_OpenClose._place（POINTER 策略开菜单）。
static var mouse_position: Vector2 = Vector2.ZERO
## 本帧累计的指针位移：一帧内多个 MouseMotion 事件相加，**帧末**由 _clear_mouse_delta 清零
## （_process 里用 call_deferred 把它排到帧末，见下）。
## 消费方一律是"每帧调用一次"的（拖拽类指令），所以必须按帧对齐，否则：
##   指针停下后没有 MouseMotion 事件，旧位移会被每帧重复叠加 → 一直漂；
##   一帧内多个事件只用最后一个 → 快移时丢距离（跟不上光标）。
## "一帧"= 一次 _process 覆盖的范围：_input 累计 → InputSys._process（按键类消费）
## → TimeSys._process（Tick 类消费，拖拽走这里）→ **本帧所有 _process 都跑完**（deferred 队列 flush）才清零。
## 被谁用：UIInteract.drag（拖拽按帧消费位移）、PointerDetect._process（位移不为 0 就派发 Pointer Move）。
static var mouse_delta: Vector2 = Vector2.ZERO
## 正在编辑输入的 UI（**开始编辑时登记**，见 UIInteract_Edit.begin_edit）；null = 没在编辑。
## 它本身就是"编辑模式"这个开关（不再另设 bool：两处状态没法保证同步）。
## 被谁用：_input（编辑中按键不进状态层、只把回车翻成提交事件）、UIInteract_Edit（登记 / 结束）、
##         PointerDetect.key（点别处时收掉）。
static var edit_ui: UIBase = null
## 当前按住的键（键值，Godot 常量）。按住期间每帧发 HOLD，松开立刻移出。
## 被谁用：_input（维护）、_process（逐帧发 HOLD）、鼠标移动判断"是否在拖拽中"。
static var keys_holding: Array[Variant] = []

func _init() -> void:
    pass

## 引擎输入入口（由 Sys._input 转发）：键/鼠标键 → 按键消息；鼠标移动 → 只累计位移。
## 要不要发 `Pointer Move` 由 PointerDetect._process 判（本帧位移不为 0 就派发给 hover 的 UI）。
## 被谁用：Sys._input。
static func _input(event: InputEvent):
    @warning_ignore_start("unsafe_property_access")
    if event is InputEventKey:
        # 正在用输入框打字（UI_Input 抢了焦点）：这些键只归它，不再翻译成状态，
        # 否则打字会顺手触发 UI 指令。
        if edit_ui != null:
            # 只有回车往外走：翻成项目自己的事件（QName.input_submit）派给正在编辑的那个输入框。
            # 为什么在这儿翻：这样"回车提交"就走**唯一输入链路**，UI_Input 不必去连引擎的
            # text_submitted 信号（全项目不连引擎信号，见 Script/UI/UI.md）。
            # echo = 按住不放的重复触发，不算提交。
            if event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
                # 多行输入框（TextEdit）默认会把回车当"插入换行"——这里显式吃掉这个事件，
                # 让"回车 = 提交"对单行 / 多行一致（多行的换行只是**显示**上自动换行，见 UI_Input）。
                Sys.sys.get_viewport().set_input_as_handled()
                edit_ui.on_event(QName.input_submit)
            return
        _send_key_status(event.keycode, event.pressed)
    elif event is InputEventMouseButton:
        _send_key_status(event.button_index, event.pressed)
    elif event is InputEventMouseMotion:
        mouse_delta += event.position - mouse_position
        mouse_position = event.position
        # 这里只累计，不发事件：要不要发 `Pointer Move` 由 PointerDetect._process 判（位移不为 0 就发）
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

## 每帧给所有按住的键发一次 HOLD（逐帧状态就是靠它驱动的，如 "Mouse Left | Tick" 拖动）。
## 顺带把"清空本帧指针位移"排到帧末（见 _clear_mouse_delta）：所以 Sys._process 那边不用再收尾。
## 被谁用：Sys._process。
static func _process(_delta: float) -> void:
    PointerDetect._process(_delta)
    for key in keys_holding:
        Msg.send_key_hold(key)
    _clear_mouse_delta.call_deferred()


## 结束编辑：清掉编辑目标，顺手把控件焦点也放掉（提交/被关掉那条路走过来时它还持有焦点）。
## 谁在编辑是 InputSys 的状态（按键翻译的开关就在 _input 里），所以"结束"也归这里——
## 放在 PointerDetect 里就要伸手改别的系统的状态，反而更绕。
## 被谁用：PointerDetect.key（点别处，见它开头那两行）、UIInteract_Edit.end_edit（指令）。
static func end_edit() -> void:
    if edit_ui != null and edit_ui.control != null:
        edit_ui.control.release_focus()
    edit_ui = null


## 帧末结算：清空本帧累计的指针位移，供下一帧重新累计（指针不动则下一帧即 (0,0)，不会漂）。
## 由 _process 用 call_deferred 排到**帧末**执行——deferred 队列在本帧所有 _process 跑完之后才 flush，
## 所以晚于 _process 的消费方（TimeSys._process 的 Tick → 拖拽/缩放）仍读得到本帧位移。
## **不能改成在 _process 里直接清零**：那会早于 Tick，拖拽就永远读到 (0,0)。
## 被谁用：_process（deferred）。
static func _clear_mouse_delta() -> void:
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
    
