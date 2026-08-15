class_name TimeSys
extends RefCounted

""" -----  ----- """
static var msgID_advance: String = "TIME_ADVANCE"
static var msgID_advance_year: String = "TIME_ADVANCE_YEAR"
static var msgID_advance_month: String = "TIME_ADVANCE_MONTH"
static var msgID_advance_xun: String = "TIME_ADVANCE_XUN"
static var msgID_advance_day: String = "TIME_ADVANCE_DAY"

""" ----- 年 月 旬 日 时辰 ----- """
static var year: int = 1
static var month: int = 1
static var xun: int = 1
static var day: int = 1
static var hour: int = 1


func _init() -> void:
    pass

func advance() -> void:
    var year_changed: bool = false
    var month_changed: bool = false
    var xun_changed: bool = false
    var day_changed: bool = false

    hour += 1
    if hour > 12:
        hour = 1
        day += 1
        day_changed = true
        if day > 10:
            day = 1
            xun += 1
            xun_changed = true
            if xun > 3:
                xun = 1
                month += 1
                month_changed = true
                if month > 12:
                    month = 1
                    year += 1
                    year_changed = true
    TimeFormat.update()
    if year_changed:
        MsgHubTime.send_advance_year(year)
    if month_changed:
        MsgHubTime.send_advance_month(month)
    if xun_changed:
        MsgHubTime.send_advance_xun(xun)
    if day_changed:
        MsgHubTime.send_advance_day(day)
    MsgHubTime.send_advance_hour(hour)