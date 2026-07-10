class_name AttributeSystem
extends RefCounted


func _init() -> void:
    AttributeSetAttack.new()


""" ---------- Impact ---------- """
static func impact(
        char_A: Character, char_B: Character, char_C: Character, 
        type_name_A: String, type_name_B: String, type_name_C: String
        ) -> AttributeSetResult:
    """ 属性交互，
        有影响者A，比较对象B，受影响者C 
        基于当前值进行影响
    """
    var attr_state_A = char_A.get_attr_state(type_name_A)
    var attr_state_B = char_B.get_attr_state(type_name_B)
    var attr_state_C := char_C.get_attr_state(type_name_C)

    var level_C = attr_state_C.get_level_cur()

    var value_A_rand = attr_state_A.get_random_level_cur()
    var value_B_rand = attr_state_B.get_random_level_cur()

    # 关系
    var relation = AttributeRelation.get_(type_name_A, type_name_B, type_name_C) 
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(value_A_rand - value_B_rand, 0) if relation.isMax else value_A_rand - value_B_rand
    # 计算变化方向，为正向或反向
    offset = offset if relation.isPositive else -offset
    var level_C_new = level_C + offset 

    return attr_state_C.set_level_cur(level_C_new)
    
static func impact_myself(char_: Character, type_name: String) -> AttributeSetResult:
    """ 自身属性变化，用于技能升级、修仙入魔等
        还没改好
    """
    var attr_state = char_.get_attr_state(type_name)
    var level = attr_state.get_level_base()
    var level_new = attr_state.get_random_level_base()
    level_new = max(level, level_new) if attr_state.isMax else level_new

    
    var result = attr_state.set_level_cur(level_new)
    return result

    