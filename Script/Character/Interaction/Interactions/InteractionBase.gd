class_name InteractionBase
extends RefCounted

@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()

func _init() -> void:
    pass


func interact(_source: Character, _target, _config: Array) -> Enums.Code:
    return Enums.Code.NULL

## 攻击比防御高(isMax=True)，则降低(isPositive=False)生命，降低值为攻击防御差值
func attack(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true
    var s_dynamic=true; var c_dynamic=true; var t_dynamic=false
    var s_before=false; var c_before=false; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type)

## 治疗量比生命高(isMax=True)，则增加(isPositive=False)生命，增加值为治疗生命差值
func heal(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = true; var isMax = true
    var s_dynamic=true; var c_dynamic=true; var t_dynamic=false
    var s_before=false; var c_before=false; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type)

## 治疗后，计算治疗前后血量差值，治疗量比生命高(isMax=True)，则降低(isPositive=False)生命，增加值为治疗生命差值
func cost(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true; 
    var s_dynamic=false; var c_dynamic=false; var t_dynamic=false
    var s_before=false; var c_before=true; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type)


# var isPositive: bool
# 在有比较对象B时(isMyself)，    最终取值有取最大值或正常输出，此时is_max表示取最大值
# 在无比较对象B时(not isMyself)，最终取值有取最大值或取最小值，此时is_max表示取最大值
# var isMax: bool    
func impact(
        char_source: Character, char_compare: Character, char_target: Character,
        source_attr_category: String, compare_attr_category: String, target_attr_category: String,
        isPositive: bool, isMax: bool, 
        source_dynamic: bool=false, compare_dynamic: bool=false, target_dynamic: bool=false,
        source_from_before: bool=false, compare_from_before: bool=false, target_from_before: bool=false, 
        source_value_type:=Enums.ValueType.CUR, compare_value_type=Enums.ValueType.CUR, target_value_type:=Enums.ValueType.CUR,
        ) -> ChangeResult:
    """ 属性交互，
        有影响者A，比较对象B，受影响者C 
        基于当前值进行影响
    """
    var attr_source = char_source.attrs
    var attr_compare = char_compare.attrs
    var attr_target := char_target.attrs

    var value_source = attr_source.get_(source_attr_category, source_value_type, source_from_before, source_dynamic)
    var value_compare = attr_compare.get_(compare_attr_category, compare_value_type, compare_from_before, compare_dynamic)
    var value_target = attr_target.get_(target_attr_category, target_value_type, target_from_before, target_dynamic)


    # 关系
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(value_source - value_compare, 0) if isMax else value_source - value_compare
    # 计算变化方向，为正向或反向
    offset = offset if isPositive else -offset
    var level_cur_new = value_target + offset 

    return attr_target.set_level_cur(target_attr_category, level_cur_new, CLASS_NAME, char_source)

    
func 熟能生巧(char_: Character, attr_category: String) -> ChangeResult:
    var attr = char_.attrs
    var level_cur = attr.get_(attr_category)
    var level_base = attr.get_(attr_category, Enums.ValueType.BASE, false, true)
    var level_cur_new = level_base if level_base > level_cur else level_cur
        
    return attr.set_level_cur(attr_category, level_cur_new, CLASS_NAME, char_)

