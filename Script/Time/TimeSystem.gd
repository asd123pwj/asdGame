class_name TimeSys
extends BaseClass
## 时间系统：按真实时间推进"时辰"，并广播时间消息（见 Script/Time/Time.md）。
## 每次推进都会 send_tick()，所以"逐帧状态"（如 "Mouse Left | Tick" 拖动）实际是**帧**驱动，
## 时钟推进是**秒**驱动——两者都在本类的 _process 里发。
## 被谁用：Sys._process（唯一驱动）；状态层的 time 监听与各 Msg.send_advance_* 的接收方。

""" -----  ----- """
## 以下四个 msgID_* 是历史遗留常量，实际发送走 Msg.send_advance_*（当前无人用这四个常量）。
static var msgID_advance: String = "TIME_ADVANCE"
static var msgID_advance_year: String = "TIME_ADVANCE_YEAR"
static var msgID_advance_month: String = "TIME_ADVANCE_MONTH"
static var msgID_advance_day: String = "TIME_ADVANCE_DAY"

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
