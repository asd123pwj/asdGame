class_name InteractionBase
extends RefCounted


func interact(_source: Character, _target: Character, _config: Variant) -> Array[Enums.Code]:
    return [Enums.Code.NULL]

## 攻击比防御高(isMax=True)，则降低(isPositive=False)生命，降低值为攻击防御差值
func attack(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax)

## 治疗量比生命高(isMax=True)，则增加(isPositive=False)生命，增加值为治疗生命差值
func heal(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = true; var isMax = true
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax)

## 治疗后，计算治疗前后血量差值，治疗量比生命高(isMax=True)，则增加(isPositive=False)生命，增加值为治疗生命差值
func 消耗(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true; 
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, false, true)


# var isPositive: bool
# 在有比较对象B时(isMyself)，    最终取值有取最大值或正常输出，此时is_max表示取最大值
# 在无比较对象B时(not isMyself)，最终取值有取最大值或取最小值，此时is_max表示取最大值
# var isMax: bool    
func impact(
        char_source: Character, char_compare: Character, char_target: Character,
        source_attr_category: String, compare_attr_category: String, target_attr_category: String,
        isPositive: bool, isMax: bool, 
        source_from_before: bool=false, compare_from_before: bool=false, target_from_before: bool=false
        ) -> ChangeResult:
    """ 属性交互，
        有影响者A，比较对象B，受影响者C 
        基于当前值进行影响
    """
    var attr_source = char_source.attrs
    var attr_compare = char_compare.attrs
    var attr_target := char_target.attrs

    var value_source = attr_source.get_(source_attr_category, Enums.ValueType.CUR, source_from_before)
    var value_compare = attr_compare.get_(compare_attr_category, Enums.ValueType.CUR, compare_from_before)
    var value_target = attr_target.get_(target_attr_category, Enums.ValueType.CUR, target_from_before)


    # 关系
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(value_source - value_compare, 0) if isMax else value_source - value_compare
    # 计算变化方向，为正向或反向
    offset = offset if isPositive else -offset
    var level_cur_C_new = value_target + offset 

    return attr_target.set_level_cur(target_attr_category, level_cur_C_new)