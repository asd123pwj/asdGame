class_name TimeSys
extends BaseClass
## 时间系统：按真实时间推进"时辰"，并广播时间消息（见 Script/Time/Time.md）。
## 每次推进都会 send_tick()，所以"逐帧状态"（如 "Right | Tick" 拖动）实际是**帧**驱动，
## 时钟推进是**秒**驱动——两者都在本类的 _process 里发。
## **另外它还管"过几秒再执行一条指令"**（`TimeSys.after` / `cancel`，见文件末尾那节"延时指令"）。
## 被谁用：Sys._process（唯一驱动）；状态层的 time 监听与各 Msg.send_advance_* 的接收方；
##         配置里的 `TimeSys.after(...)`（悬停提示就是用它把"弹说明"延后到鼠标停住之后）。

""" ----- 年 月 旬 日 时辰 ----- """
## 当前时间（都是 1 起算：年/月 1-12、日 1-30、时辰 1-12）。
## 被谁用：TimeFormat.update（转中文）、状态的 time 监听、各处展示。
static var year: int = 1
static var month: int = 1
static var day: int = 1
static var hour: int = 1

""" ----- 内部计时 ----- """
## 累计真实经过时间（秒）
static var elapse: float = 0.0        # 累计真实经过时间（秒）
## 距离上次推进时辰的累计时间（秒）；到 SysCfg.hour_period 就推进一次并扣掉一个周期。
static var _period_accum: float = 0.0 # 距离上次推进时辰的累计时间（秒）

func _init() -> void:
    pass


## 每帧累加真实时间；够一个时辰周期就 advance()；最后无条件 send_tick()。
## 被谁用：Sys._process（必须在 InputSys._process 之后——本帧的指针位移就是在这里被消费的，
## 而清零被 InputSys 排到了帧末的 deferred 队列里）。
static func _process(delta: float) -> void:
    elapse += delta
    _period_accum += delta
    var period: float = Sys.sysCfg.hour_period
    if period > 0.0 and _period_accum >= period:
        _period_accum -= period   # 保留余量，避免多帧累积丢时间
        advance()
    _tick_delays(delta)           # 延时指令倒计时（见文件末尾那节）
    Msg.send_tick()
    

## 推进一个时辰（12 时辰 = 1 日 30 日 = 1 月 12 月 = 1 年），刷新中文格式，并按变化粒度广播。
## 被谁用：_process（到点自动）、需要手动推进时间的地方。
static func advance() -> void:
    var year_changed: bool = false
    var month_changed: bool = false
    var day_changed: bool = false

    hour += 1
    if hour > 12:
        hour = 1
        day += 1
        day_changed = true
        if day > 30:
            day = 1
            month += 1
            month_changed = true
            if month > 12:
                month = 1
                year += 1
                year_changed = true
    TimeFormat.update()
    if year_changed:
        Msg.send_advance_year(year)
    if month_changed:
        Msg.send_advance_month(month)
    if day_changed:
        Msg.send_advance_day(day)
    Msg.send_advance_hour(hour)


""" ----- 延时指令（"过几秒再执行一条指令"）----- """
## 一条待执行的延时：`{ from, cmd, event, left, delay, cancel_on, cancel_id, cancel_cb }`。
##   · cmd：到点要执行的指令串（原样存着；指令里的 `@self` 等**在执行时**才解析）；
##   · from：**登记时正在派发事件的那个元素**（内部字段，不是给配置写的参数）——管执行时
##     `@self` / `@host` 的落点（延时执行时已经没有"当前元素"了，见 CommandParser.event_ui 那条提醒）；
##   · event：登记时的事件名（执行时当 `@event` 用，见 _tick_delays）；
##   · left / delay：还剩多少秒 / 这次给的等待秒数（重置时两个都换成新的）；
##   · cancel_on：取消条件 = **角色状态名**（空 = 不设取消条件）；cancel_id / cancel_cb = 那条**一次性**
##     监听的凭据（作废时按它退订，见 _arm_cancel / _unlisten）。
##     **看哪个角色的状态不存进条目**：订监听那一刻用一次就完了（默认 SYS 角色，见 after 的 char_）。
## **"同一条"只看 `cmd`**（同一串指令就是同一条，不记谁登记的）——两处写一样的指令会共用一条。
## 以后真要"按谁登记的分开算/分开取消"，**再加一个 who 参数**即可（现在不用）。
## 被谁用：after / cancel / cancel_all / _tick_delays（都在这下面）。
static var _delays: Array[Dictionary] = []


## **延时执行一条指令**：`seconds` 秒之后（真实时间，与 tick 同一把尺、不看时辰快慢）执行 `cmd`。
## **同一条再次调用 = 只把等待时间重置**（不新增一条）：判"同一条" = **同一串 cmd**。
## 于是"鼠标一直在动 ⇒ 一直在重置"，只有停住不动满 seconds 才真的执行——这就是悬停提示的用法：
##   `TimeSys.after(0.5, 'UIInteract.open(@self, "Tip", @self, content="…")', cancel_on="Pointer Move")`
##   （写在 `UIPreset_Basic.tip_open_cmd` 里，**全项目的说明浮窗都从那一处来**；`pointer_move` 每次触发
##    就重置一次，停住 TOOLTIP_DELAY 秒才弹。）
## 参数：
##   · seconds：等多少秒（负数按 0 算）；
##   · cmd：要执行的指令串，写法与别处完全一样；
##   · cancel_on：**取消条件 = 角色状态名**——那条状态一满足，这条待执行就作废
##     （订的是一次性的"状态满足"监听，见 _arm_cancel）：
##       · "鼠标一动就作废"写 `QName.pointer_move`——配合"同一条重置"正好是"**停住才执行**"（提示浮窗用它）；
##       · 别的系统状态同理（如 `QName.pointer1_hold` = 按住就作废）。
##   · char_：取消条件看**哪个角色**的状态——**不写 = SYS 角色**（`Sys.sys_status`：输入 / 时间 / 编辑
##     那批系统状态都挂在它身上，`QName.pointer_move` 也在它身上；说明浮窗走的就是这个默认）；
##     要看某个具体角色的状态（如"某角色受伤就作废"）就把那个角色传进来（取值链也行，如 `@Char/人类`）。
## **要写 `@self` / `@host` 的指令就在事件派发里登记**（配置的 events 里就是这么用的）：
## 登记时记下当时的元素，执行前摆回去——延时执行时早就没有"当前事件"了（见 CommandParser.event_ui
## 那条提醒：不在派发链上的指令别写 `@self`）。**从非事件处调用**（脚本里手动排一条）也照写，
## 只是那时没有 `@self` 可解析（会把 `@self` 当没解析到，照旧警告），用 `@注册名` 指对象即可。
## 被谁用：配置里包住一条指令（说明浮窗那处见 UIPreset_Basic.tip_open_cmd）。
static func after(seconds: float, cmd: String, cancel_on: String = "", char_: Character = null) -> void:
    if cmd.is_empty():
        push_warning("TimeSys.after: 指令串是空的，忽略")
        return
    var delay: float = maxf(seconds, 0.0)
    # 取消条件看哪个角色（不写 = SYS 角色：系统状态都挂在它身上，见 _arm_cancel）
    var owner: Character = char_ if char_ != null else Sys.sys_status
    var idx: int = _delay_index_of(cmd)
    if idx >= 0:
        # **重置**：换成这次给的等待秒数（比原来的长、短都换）；取消条件也按这次重新订一遍
        # （先把上次那条监听退掉）。不新增一条 ⇒ "同一条指令"永远只有一个待执行
        # （等 3 秒的中途收到"等 5 秒"的同一条 ⇒ 从此刻起重新数 5 秒）。
        var entry: Dictionary = _delays[idx]
        _unlisten(entry)
        entry["delay"] = delay
        entry["left"] = delay
        entry["from"] = CommandParser.event_ui
        entry["event"] = CommandParser.event_name
        _arm_cancel(entry, cancel_on, owner)
        return
    var fresh: Dictionary = {
        "from": CommandParser.event_ui, "cmd": cmd, "event": CommandParser.event_name,
        "left": delay, "delay": delay,
    }
    _delays.append(fresh)
    _arm_cancel(fresh, cancel_on, owner)


## 取消待执行的延时指令：给 cmd 就取消**那一串指令**的待执行；要"一条不留"用 cancel_all。
## 判据同 after：**只看指令串**。被谁用：想让"某某事一到就作废"又不想用 cancel_on 的场合。
static func cancel(cmd: String) -> void:
    if cmd.is_empty():
        push_warning("TimeSys.cancel: 没给指令串（要全清用 cancel_all）")
        return
    var idx: int = _delay_index_of(cmd)
    if idx >= 0:
        _drop(idx)


## 清空所有待执行的延时指令（热重载 / 调试 / "全部作废"用）。
static func cancel_all() -> void:
    for i in range(_delays.size() - 1, -1, -1):
        _drop(i)


## 给这条延时**订"取消条件"**：`cancel_on`（`status_name`）是**角色状态名**，看**哪个角色**由 `char_` 决定
## （after 里定：不写 = SYS 角色）。订的是**一次性**的"状态满足"监听
## （`Msg.listen_status_satisfied(char_, status_name, cb, once=true)`）：那条状态一满足，就把这条延时作废
## （见 _on_cancel_hit）。只认一次，命中后 MessageBus 自己就把监听摘掉了。
## **为什么要自己存凭据（cancel_id / cancel_cb）**：没命中、却先到点或先被取消的场合，那条监听
## 还挂在消息表上，得由 _unlisten 主动退掉——不然每悬停一次就留一条（越攒越多）。
## 被谁用：after（新登记与重置两处）。
static func _arm_cancel(entry: Dictionary, status_name: String, char_: Character) -> void:
    entry["cancel_on"] = status_name
    entry["cancel_id"] = ""
    entry["cancel_cb"] = null
    if status_name.is_empty():
        return
    if char_ == null:
        # 没拿到角色（如 SYS 角色还没建就有人排延时）：这条**照排**，只是没有取消条件——说一声免得静默失效。
        push_warning("TimeSys.after: cancel_on=\"%s\" 要按状态取消，但没拿到角色，这条不设取消条件" % status_name)
        return
    var cmd: String = str(entry["cmd"])
    var cb: Callable = func(_msg): _on_cancel_hit(cmd)
    entry["cancel_cb"] = cb
    entry["cancel_id"] = Msg.listen_status_satisfied(char_, status_name, cb, true)


## 取消条件命中（那条状态满足了）：把对应的待执行作废（按指令串找，见 _delay_index_of）。
## **不再退订**：一次性监听在广播前**已经被 MessageBus 摘掉**了（见它"一次性接收器"那段）。
## 被谁用：_arm_cancel 订的那个监听。
static func _on_cancel_hit(cmd: String) -> void:
    var idx: int = _delay_index_of(cmd)
    if idx >= 0:
        _delays.remove_at(idx)


## 作废第 i 条：**退掉它的取消条件监听**，再从表里摘掉。
## 被谁用：cancel / cancel_all / _tick_delays（到点的、落点没了的）。
static func _drop(i: int) -> void:
    _unlisten(_delays[i])
    _delays.remove_at(i)


## 退掉这条延时订的"取消条件"监听（没订就什么都不做）。凭据见 _arm_cancel。
## 被谁用：_drop、after（重置时先退旧的）、_tick_delays（到点执行前）。
static func _unlisten(entry: Dictionary) -> void:
    var msg_id: String = str(entry.get("cancel_id", ""))
    var cb: Variant = entry.get("cancel_cb")
    if msg_id != "" and cb is Callable:
        MsgBus.unlisten(msg_id, cb)


## 每帧倒计时（TimeSys._process 调）：到点的挑出来**先摘掉再执行**。
## **执行前把"当前元素 / 事件名"摆回登记时的那个**：`@self` / `@host` / `@event` 全靠它解析
## （延时执行时已经没有"当前事件"了，见 CommandParser.event_ui 那条提醒），执行完还原——
## 指令里若又派发事件（嵌套），里层才不会把外层盖掉。
## 遍历/修改分开：指令里可能又登记（如"每次都再延一次"）或取消，边遍历边改会跳过条目。
## 被谁用：_process。
static func _tick_delays(delta: float) -> void:
    if _delays.is_empty():
        return
    for entry: Dictionary in _delays:
        entry["left"] = float(entry["left"]) - delta
    var due: Array = []
    for i in range(_delays.size() - 1, -1, -1):
        var entry: Dictionary = _delays[i]
        var from_obj: Object = entry["from"]
        if from_obj != null and not is_instance_valid(from_obj):
            _drop(i)                  # 登记它的那个元素已经没了（动态删掉的 UI）：没有落点了，作废
            continue
        if float(entry["left"]) <= 0.0:
            _unlisten(entry)          # 到点：取消条件不必再听了
            due.push_front(entry)     # 先摘出来（保持登记顺序执行）
            _delays.remove_at(i)
    for entry: Dictionary in due:
        var prev_ui: Object = CommandParser.event_ui
        var prev_name: String = CommandParser.event_name
        CommandParser.event_ui = entry["from"]
        CommandParser.event_name = str(entry["event"])
        Msg.send_cmd(str(entry["cmd"]))
        CommandParser.event_ui = prev_ui
        CommandParser.event_name = prev_name


## "同一条"的判据：**同一串 cmd**（就这么一条，不看谁登记的）。
## 返回下标，-1 = 没登记过。被谁用：after / cancel / _on_cancel_hit。
static func _delay_index_of(cmd: String) -> int:
    for i in _delays.size():
        if str(_delays[i]["cmd"]) == cmd:
            return i
    return -1
