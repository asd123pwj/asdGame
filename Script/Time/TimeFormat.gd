class_name TimeFormat
extends BaseClass
## 时间的中文显示（年/月/旬/日/时辰），从 TimeSys 的数字换算而来。
## 被谁用：需要"给人看的时间文本"的地方（打印/日志/UI 展示）。

## 下面五个都是**给人和 UI 看的字符串**（由 update() 从 TimeSys 的数字刷新）。
## 被谁用：日志/UI 展示（如 Test 里的 year+month+day+hour 打印）。
static var year: String
static var month: String
static var xun: String
static var day: String
static var hour: String

static var _月: Array = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
# static var _旬: Array = ["上旬", "中旬", "下旬"]
static var _日 = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
           "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
           "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
static var _时辰: Array = ["子时", "丑时", "寅时", "卯时", "辰时", "巳时", "午时", "未时", "申时", "酉时", "戌时", "亥时"]

## 把 TimeSys 的当前数字刷成中文字符串。
## 被谁用：TimeSys.advance（每次时间推进后）。
static func update() -> void:
    year = year_to_chinese(Sys.timeSys.year)
    month = _月[Sys.timeSys.month - 1]
    day = _日[Sys.timeSys.day - 1]
    hour = _时辰[Sys.timeSys.hour - 1]


## 一句话的"现在"：`元年正月初一 子时`。
## 直接按 TimeSys 当下的数字现算（**不依赖 `update()` 跑没跑过**：开局那几个缓存字符串可能还是空的）。
## 被谁用：需要把**当下**冻住记下来的地方（如 `Interactions.history`——交互触发只持续一帧，
## 得把"当时是几时"留住，过后再算只会得到"现在"，不是"那一刻"）。
static func now_text() -> String:
    return "%s%s%s %s" % [year_to_chinese(TimeSys.year), _月[TimeSys.month - 1],
        _日[TimeSys.day - 1], _时辰[TimeSys.hour - 1]]


## 年份数字转中文（如 1→"元"，2→"二"，10→"十"，123→"一百二十三"）
## 被谁用：update。
static func year_to_chinese(num: int) -> String:
    if num <= 0:
        return "零年"
    if num == 1:
        return "元年"      # 第一年特称“元年”
    return _number_to_chinese(num) + "年"

## 内部数字转中文（支持0~99999，可根据需要扩展）
## 被谁用：year_to_chinese。
static func _number_to_chinese(num: int) -> String:
    const DIGITS = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
    const UNITS = ["", "十", "百", "千", "万"]
    
    if num == 0:
        return "零"
    
    var str_num = str(num)
    var length = str_num.length()
    var result = ""
    var zero_flag = false
    
    for i in range(length):
        var digit = int(str_num[i])
        var place = length - i - 1
        
        if digit == 0:
            zero_flag = true
        else:
            if zero_flag:
                result += "零"
                zero_flag = false
            result += DIGITS[digit]
            if place > 0 and place < len(UNITS):
                result += UNITS[place]
    
    return result
