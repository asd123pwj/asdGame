class_name RaceType
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var types: Array[String]
var buffs: Array[String]
var statuses: Array[String]

""" ----- Global ----- """
static var _we: Dictionary[String, RaceType] = {}
# static var new_: Callable

func _init(name: String, types: Array=[], buffs: Array=[], statuses: Array=[]) -> void:
    _we[name] = self
    self.name = name
    self.types.assign(types.filter(func(x): return x is String))
    self.buffs.assign(buffs.filter(func(x): return x is String))
    self.statuses.assign(statuses.filter(func(x): return x is String))

static func get_(name: String) -> RaceType:
    return _we[name]
