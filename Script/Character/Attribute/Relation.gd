class_name Relation
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
static var _we: Dictionary[String, Relation] = {}

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

static func get_(typeA: String, typeB: String, typeC: String) -> Relation:
    return _we[naming(typeA, typeB, typeC)]

    
static func impact(
        char_A: Character, char_B: Character, char_C: Character, 
        attr_type_name_A: String, attr_type_name_B: String, attr_type_name_C: String
        ) -> ChangeResult:
    """ 属性交互，
        有影响者A，比较对象B，受影响者C 
        基于当前值进行影响
    """
    var attr_A = char_A.attrs
    var attr_B = char_B.attrs
    var attr_C := char_C.attrs

    # var level_cur_C = attr_C.get_level_cur(attr_type_name_C)

    # var level_final_A = attr_A.get_level_final(attr_type_name_A)
    # var level_final_B = attr_B.get_level_final(attr_type_name_B)
    var level_final_A = attr_A.get_(attr_type_name_A)
    var level_final_B = attr_B.get_(attr_type_name_B)
    var level_cur_C = attr_C.get_(attr_type_name_C)


    # 关系
    var relation = get_(attr_type_name_A, attr_type_name_B, attr_type_name_C) 
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(level_final_A - level_final_B, 0) if relation.isMax else level_final_A - level_final_B
    # 计算变化方向，为正向或反向
    offset = offset if relation.isPositive else -offset
    var level_cur_C_new = level_cur_C + offset 

    return attr_C.set_level_cur(attr_type_name_C, level_cur_C_new)