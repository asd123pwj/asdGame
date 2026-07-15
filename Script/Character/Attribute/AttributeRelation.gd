class_name AttributeRelation
extends PresetRegister



""" ----- individual ----- """
var attr_type_name_A: String
var attr_type_name_B: String
var attr_type_name_C: String
var isPositive: bool
# 在有比较对象B时(isMyself)，    最终取值有取最大值或正常输出，此时is_max表示取最大值
# 在无比较对象B时(not isMyself)，最终取值有取最大值或取最小值，此时is_max表示取最大值
var isMax: bool    
var isMyself: bool

""" ----- Global ----- """
static var new_: Callable
static var _we: Dictionary[String, AttributeRelation] = {}

func _init(attr_type_name_A: String, attr_type_name_B: String, attr_type_name_C: String, isPositive: bool, isMax: bool, isMyself: bool = false) -> void:
    _we[naming(attr_type_name_A, attr_type_name_B, attr_type_name_C)] = self
    self.attr_type_name_A = attr_type_name_A
    self.attr_type_name_B = attr_type_name_B
    self.attr_type_name_C = attr_type_name_C
    self.isPositive = isPositive
    self.isMax = isMax
    self.isMyself = isMyself

static func naming(typeA: String, typeB: String, typeC: String) -> String:
    return typeA + " | " + typeB + " | " + typeC

static func get_(typeA: String, typeB: String, typeC: String) -> AttributeRelation:
    return _we[naming(typeA, typeB, typeC)]