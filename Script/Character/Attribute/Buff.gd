class_name Buff
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var category: String
var value_type: Enums.ValueType
var value: int
var method: Enums.ModificationMethod


""" ----- Global ----- """
static var _we: Dictionary[String, Buff] = {}


""" ---------- Init ---------- """
## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
func _init(
        name: String,
        category: String,
        value_type: Enums.ValueType,
        value: int,
        method: Enums.ModificationMethod = Enums.ModificationMethod.ADD
        ) -> void:
    _we[name] = self
    self.name = name
    self.category = category
    self.value_type = value_type
    self.value = value
    self.method = method

static func get_(name: String) -> Buff:
    return _we[name]

func apply(value: int) -> int:
    if method == Enums.ModificationMethod.ADD:
        return self.value + value
    elif method == Enums.ModificationMethod.SUBTRACT:
        return self.value - value
    elif method == Enums.ModificationMethod.MULTIPLY:
        return self.value * value
    elif method == Enums.ModificationMethod.DIVIDE:
        @warning_ignore("integer_division")
        return self.value / value
    elif method == Enums.ModificationMethod.SET:
        return self.value
    else:
        return self.value

