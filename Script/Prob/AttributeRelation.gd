class_name AttributeRelation
extends RefCounted



""" ----- individual ----- """
var typeA: String
var typeB: String
var typeC: String
var isPositive: bool
# 在有比较对象B时(isMyself)，    最终取值有取最大值或正常输出，此时is_max表示取最大值
# 在无比较对象B时(not isMyself)，最终取值有取最大值或取最小值，此时is_max表示取最大值
var isMax: bool    
var isMyself: bool

""" ----- Global ----- """
static var we: Dictionary[String, AttributeRelation] = {}

func _init(typeA: String, typeB: String, typeC: String, isPositive: bool, isMax: bool, isMyself: bool = false) -> void:
    self.typeA = typeA
    self.typeB = typeB
    self.typeC = typeC
    self.isPositive = isPositive
    self.isMax = isMax
    self.isMyself = isMyself
    we[naming(typeA, typeB, typeC)] = self

static func naming(typeA: String, typeB: String, typeC: String) -> String:
    return typeA + " | " + typeB + " | " + typeC

static func get_(typeA: String, typeB: String, typeC: String) -> AttributeRelation:
    return we[naming(typeA, typeB, typeC)]