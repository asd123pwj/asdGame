class_name ListenType
extends RefCounted


var name: Variant
var match_type: Variant
var thres: int

func _init(name: Variant, match: Variant = null, thres: int = INT64_MIN) -> void:
    self.name = name
    self.match_type = match
    self.thres = thres

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