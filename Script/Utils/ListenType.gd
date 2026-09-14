class_name ListenType
extends BaseClass
## 监听条件：状态/属性/按键等"某一个名字 + 一个比较条件"的声明（见 Config/Character/Status/*.gd）。
## 配置里写成 [name, condition, 阈值] 这种简写，由 StatusPreset 用 ListenType.new.callv(cfg) 造出来。
## 被谁用：StatusPreset 的 _attr/_buff/_status/_interaction/_key/_time_listeners ——
##           每个监听条件就是一个 ListenType，判定时调它的 check()。

## 被监听的名字（属性名/状态名/按键常量…，含义由所在列表决定）。
## 被谁用：StatusPreset（拼监听的 ID 与标签）。
var name: Variant
## 比较条件字符串（"==" / "!=" / ">=" / "<=" / ">" / "<"，可带前缀，如 ">Base/"）。
## 被谁用：check。
var match_type: Variant
## 阈值（配置里给的固定值，如数值门槛）。
## 被谁用：check（当调用方没给"当前值"时用它）。
var thres: int

## 造一条监听条件（match/thres 可省，见各配置里的简写）。
## 被谁用：StatusPreset 的 ListenType.new.callv(cfg)。
func _init(name: Variant, match: Variant = null, thres: int = INT64_MIN) -> void:
    self.name = name
    self.match_type = match
    self.thres = thres

## 判定 a 是否满足本条件：b 为 int 时用 b 当阈值，否则用 thres。
## 注意 match_type 用 begins_with，所以 ">Base/" 这类前缀写法也走同一套比较。
## 被谁用：StatusPreset 判定属性/状态/时间等是否满足。
func check(a: int, b = null) -> bool:
    var compare: int = thres
    if typeof(b) == TYPE_INT:
        compare = b
    else:
        print("TODO: 报错check")
    @warning_ignore_start("unsafe_method_access")
    if match_type.begins_with("=="):
        return a == compare
    elif match_type.begins_with("!="):
        return a != compare
    elif match_type.begins_with(">="):
        return a >= compare
    elif match_type.begins_with("<="):
        return a <= compare
    elif match_type.begins_with(">"):
        return a > compare
    elif match_type.begins_with("<"):
        return a < compare
    else:
        return false
