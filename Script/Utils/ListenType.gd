class_name ListenType
extends RefCounted


var name: String
var match_type: String
var thres: int

func _init(name: String, match: String, thres: int = INT64_MIN) -> void:
    self.name = name
    self.match_type = match
    self.thres = thres

func check(value: int) -> bool:
    if match_type == "==":
        return value == thres
    elif match_type == "!=":
        return value != thres
    elif match_type == ">=":
        return value >= thres
    elif match_type == "<=":
        return value <= thres
    elif match_type == ">":
        return value > thres
    elif match_type == "<":
        return value < thres
    else:
        return false