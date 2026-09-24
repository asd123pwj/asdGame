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
## 被谁用：_input（编辑中**只拦住归输入框自己的键**，其余键照旧进状态层）、
##         UIInteract_Edit（登记 / 结束，"正在编辑"还会发成一条状态，见 QName.editing）、
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
        # 按下这一刻在不在编辑（取一次，别读两次：下面的派发可能顺手把编辑收掉）。
        var editing: bool = edit_ui != null
        # ① 归**输入框自己**的键（会打字的键 + 方向键 / 退格 / 删除 / Tab…，见 _is_input_only_key）
        #    ⇒ 不进状态层，就地结束（交给控件自己处理）。
        if editing and _is_input_only_key(event):
            return
        # ② 其余键一律**照常发进状态层**——修饰键、功能键、回车都是；
        #    "要不要响应""这么按算不算提交"全由状态说了算，输入层只如实转发。
        _send_key_status(event.keycode, event.pressed)
        # ③ 回车再多做一件："这么按算不算提交"（问 `QName.submit`）：算 ⇒ **吃掉这个事件**
        #    （多行框才不会顺手插一个换行；按着 Shift 不算 ⇒ 不吃 ⇒ 让多行框插换行）。
        #    顺序不能反：得先把回车发进状态层（`_submit_now` 要结算"回车正按着"）。
        #    提交本身不在这儿做——状态侧派发 `QName.input_submit`（见 SystemManager.when_submit）。
        if editing and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER] and _submit_now():
            Sys.sys.get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        _send_key_status(event.button_index, event.pressed)
    elif event is InputEventMouseMotion:
        mouse_delta += event.position - mouse_position
        mouse_position = event.position
        # 这里只累计，不发事件：要不要发 `Pointer Move` 由 PointerDetect._process 判（位移不为 0 就发）
        # print(mouse_position)
    @warning_ignore_restore("unsafe_property_access")

## 每帧给所有按住的键发一次 HOLD（逐帧状态就是靠它驱动的，如 "Right | Tick" 拖动）。
## 顺带把"清空本帧指针位移"排到帧末（见 _clear_mouse_delta）：所以 Sys._process 那边不用再收尾。
## 被谁用：Sys._process。
static func _process(_delta: float) -> void:
    PointerDetect._process(_delta)
    for key in keys_holding:
        Msg.send_key_hold(key)
    _clear_mouse_delta.call_deferred()


## 开始编辑：置上编辑目标 + 告诉状态层"正在编辑"（`QName.editing` 那条**保持型**外部检测）。
## **两件事必须成对**（少发那条消息，配置里"编辑中要屏蔽谁""回车算不算提交"就全失效），所以都放这儿，
## 别在别处自己赋 `edit_ui`。抢焦点 / 全选是 UI 那边的活，由 `UIInteract_Edit.begin_edit` 接着做。
## 被谁用：UIInteract_Edit.begin_edit。
static func begin_edit(ui: UIBase) -> void:
    edit_ui = ui
    Msg.send_status_detected_manual(Sys.sys_status, QName.editing)


## 结束编辑：清掉编辑目标 + 放掉控件焦点 + 告诉状态层"没在编辑了"。
## **任何路径收编辑都得走这里**：`UIInteract.end_edit` 命令、以及"点别处"（PointerDetect.key 开头那两行）。
## 以前只有命令那条路发了状态消息 ⇒ "点别处"收掉编辑时状态层还停在"编辑中"（实测踩过）。
## 被谁用：UIInteract_Edit.end_edit、PointerDetect.key。
static func end_edit() -> void:
    if edit_ui == null:
        return                      # 本来就没在编辑：什么都不做（别白发一条"没在编辑了"）
    if edit_ui.control != null:
        edit_ui.control.release_focus()
    edit_ui = null
    Msg.send_status_undetected_manual(Sys.sys_status, QName.editing)


## 帧末结算：清空本帧累计的指针位移，供下一帧重新累计（指针不动则下一帧即 (0,0)，不会漂）。
## 由 _process 用 call_deferred 排到**帧末**执行——deferred 队列在本帧所有 _process 跑完之后才 flush，
## 所以晚于 _process 的消费方（TimeSys._process 的 Tick → 拖拽/缩放）仍读得到本帧位移。
## **不能改成在 _process 里直接清零**：那会早于 Tick，拖拽就永远读到 (0,0)。
## 被谁用：_process（deferred）。
static func _clear_mouse_delta() -> void:
    mouse_delta = Vector2.ZERO

## 编辑中**只归输入框、不进状态层**的"操作键"：方向键 + 退格 / 删除 / Tab。
## 方向键要在这儿拦下来，是因为**输入框用的是内置的方向键**（移动光标），不是我们的
## `QName.left / right / up / down` 方向状态——放过去的话，打字时按方向键会顺手触发走路 / 开菜单。
## 退格 / 删除 / Tab 同理（"改字"归输入框，"打字"的 `unicode > 0` 已经覆盖了，这三个得显式列）。
## **不含** Home / End / PageUp / PageDown：那是"跳行首 / 翻屏"这类**浏览用键**，本项目的框又小又短，
## 用不上；不列在这里 ⇒ 它们照常进状态层（将来想拿它们绑别的状态也不会被输入框抢走）。
## **回车也不在表里**：它照常进状态层，提交与否由状态说了算（见 _input）。
## 被谁用：_input（编辑中那一支）。
const INPUT_ONLY_KEYS: Array[int] = [
    KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN,
    KEY_BACKSPACE, KEY_DELETE, KEY_TAB,
]


## 这个键是不是"归输入框自己"（编辑中要拦住、不进状态层）：操作键（上面那张表）+ 会打字的键。
## 会打字的判据用 `unicode > 0`：字母 / 数字 / 标点 / 空格 / 输入法都自动覆盖；
## 而修饰键 / 功能键 / 其它系统键的 unicode 是 0 ⇒ 自然放行（它们照旧进状态层）。
## 被谁用：_input（编辑中那一支）。
static func _is_input_only_key(event: InputEventKey) -> bool:
    if event.keycode in INPUT_ONLY_KEYS:
        return true
    return event.unicode > 0


## 这一次回车**算不算提交**：**问你配的那个状态** `QName.submit`（= 回车 ∧ 没按 Shift，见 Archetype_System）。
## 为什么要"当场"问：控件是在**事件传播**里就插换行的，而 HOLD 类状态本来是 `Sys._process` 逐帧发的 ⇒
## 先把当前按住的键补一次 HOLD（把状态**结算到当下**，含刚按下的回车与按着的 Shift），再读结论；
## 不结算的话"Shift+回车"会被当成普通回车（实测踩过）。
## 没配这个状态（换一套配置 / SYS 还没建）⇒ 返回 false = **不吃**：回车就是普通回车（多行插换行），
## 不至于被静默吞掉又什么都不发生。
## **这里只判"要不要吃掉事件"，不派发提交**——派发在状态侧（`SystemManager.when_submit`），
## 所以"提交是什么"仍旧只由配置说了算。
## 被谁用：_input（编辑中按回车那一支）。
static func _submit_now() -> bool:
    for key in keys_holding:
        Msg.send_key_hold(key)
    var char_: Character = Sys.sys_status
    if char_ == null or char_.statuses == null or not char_.statuses.check_exist(QName.submit):
        return false
    return char_.statuses.check_satisfied(QName.submit)


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
    
