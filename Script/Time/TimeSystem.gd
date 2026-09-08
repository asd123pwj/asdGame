class_name TimeSys
extends BaseClass

""" -----  ----- """
static var msgID_advance: String = "TIME_ADVANCE"
static var msgID_advance_year: String = "TIME_ADVANCE_YEAR"
static var msgID_advance_month: String = "TIME_ADVANCE_MONTH"
static var msgID_advance_day: String = "TIME_ADVANCE_DAY"

""" ----- 年 月 旬 日 时辰 ----- """
static var year: int = 1
static var month: int = 1
static var day: int = 1
static var hour: int = 1

""" ----- 内部计时 ----- """
static var elapse: float = 0.0        # 累计真实经过时间（秒）
static var _period_accum: float = 0.0 # 距离上次推进时辰的累计时间（秒）

func _init() -> void:
    pass


static func _process(delta: float) -> void:
    elapse += delta
    _period_accum += delta
    var period: float = Sys.sysCfg.hour_period
    if period > 0.0 and _period_accum >= period:
        _period_accum -= period   # 保留余量，避免多帧累积丢时间
        advance()
    Msg.send_tick()
    

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