class_name AttrSys
extends RefCounted


# func _init() -> void:
#     PresetRegister.register(AttributeType)
#     PresetRegister.register(AttributeBuff)
#     PresetRegister.register(AttributeRelation)
#     PresetRegister.register(AttributeSet)


""" ---------- Impact ---------- """
static func impact(
        char_A: Character, char_B: Character, char_C: Character, 
        attr_type_name_A: String, attr_type_name_B: String, attr_type_name_C: String
        ) -> ChangeResult:
    """ 属性交互，
        有影响者A，比较对象B，受影响者C 
        基于当前值进行影响
    """
    var attr_A = char_A.attr
    var attr_B = char_B.attr
    var attr_C := char_C.attr

    var level_cur_C = attr_C.get_level_cur(attr_type_name_C)

    var level_final_A = attr_A.get_level_final(attr_type_name_A)
    var level_final_B = attr_B.get_level_final(attr_type_name_B)

    # 关系
    var relation = AttributeRelation.get_(attr_type_name_A, attr_type_name_B, attr_type_name_C) 
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(level_final_A - level_final_B, 0) if relation.isMax else level_final_A - level_final_B
    # 计算变化方向，为正向或反向
    offset = offset if relation.isPositive else -offset
    var level_cur_C_new = level_cur_C + offset 

    return set_level_cur(attr_C, attr_type_name_C, level_cur_C_new)
    
# static func impact_myself(char_: Character, type_name: String) -> ChangeResult:
#     """ 自身属性变化，用于技能升级、修仙入魔等
#         还没改好
#     """
#     return null
    # var attr_state = char_.get_attr(type_name)
    # var level = attr_state.get_level_base()
    # var level_new = attr_state.get_random_level_base()
    # level_new = max(level, level_new) if attr_state.isMax else level_new

    
    # var result = attr_state.set_level_cur(level_new)
    # return result

    
## 设置当前等级
## @param level_new: 新等级
static func set_level_cur(attr: Attribute, attr_type_name: String, level_new: int) -> ChangeResult:
    var level_ori = attr.get_level_cur(attr_type_name)
    var level_offset = level_new - level_ori
    var code: Enums.Code
    if level_new > attr.get_level_min(attr_type_name):
        attr._level_curs[attr_type_name] = level_new
        if level_ori != level_new:
            code = Enums.Code.OK
            MsgHubChar.send_type_changed(attr.me, attr_type_name, level_new)
        else:
            code = Enums.Code.NOT_MODIFIED
    else:
        if attr.get_attr_type(attr_type_name).allow_negative:
            attr._level_curs[attr_type_name] = level_new
            MsgHubChar.send_type_changed(attr.me, attr_type_name, level_new)
        code = Enums.Code.FORBIDDEN

    return ChangeResult.new(
        code, level_ori, level_new, level_offset
    )
