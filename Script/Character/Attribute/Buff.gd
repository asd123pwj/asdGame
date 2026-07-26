class_name Buff
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var category: String
var value_type: Enums.ValueType
var value #: int | String
var method: Enums.ModificationMethod


""" ----- Global ----- """
static var _we: Dictionary[String, Buff] = {}


""" ---------- Init ---------- """
## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
func _init(
        name: String,
        category: String,
        value_type: Enums.ValueType,
        value,#: int | String
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

func apply(value: int, char_: Character) -> int:
    var value_offset: int
    match typeof(self.value):
        TYPE_INT:
            value_offset = self.value
        TYPE_STRING:
            if char_.attrs == null or (not char_.attrs.check_attribute(self.value)):
                value_offset = 0
            else:
                value_offset = char_.attrs.get_(self.value)
    if method == Enums.ModificationMethod.ADD:
        return value + value_offset
    elif method == Enums.ModificationMethod.SUBTRACT:
        return value - value_offset
    elif method == Enums.ModificationMethod.MULTIPLY:
        return value * value_offset
    elif method == Enums.ModificationMethod.DIVIDE:
        @warning_ignore("integer_division")
        return value / value_offset
    elif method == Enums.ModificationMethod.SET:
        return value_offset
    else:
        return value_offset

