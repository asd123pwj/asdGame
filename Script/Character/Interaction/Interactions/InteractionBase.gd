class_name InteractionBase
extends BaseClass
## 交互实现基类：所有"具体交互"都继承它，并覆写 `interact(source, target)`。
## 触发时机由所属 InteractionPreset 决定（依赖状态满足时调 interact），target 取自那条状态最近的消息。
## 本类还提供三种通用结算套路（attack / heal / cost）与它们的公共实现 impact，
## 以及成长用的 practice——子类只挑需要的用。
## 被谁用：InteractionPreset._get_interaction_by_name（按类名 new 出来）。

## 预设名（= InteractionPreset.name）。被谁用：结算时作为"谁造成的改变"记进属性。
var name: String
## 预设给的参数（含义由子类自己解释，如属性名、buff 名）。被谁用：各子类。
var config

## 记下预设名与参数。被谁用：InteractionPreset._get_interaction_by_name。
func _init(name: String, config) -> void:
    self.name = name
    self.config = config



## 虚接口：执行一次交互，返回结果数组（元素多为 ChangeResult / Enums.Code）。
## 被谁用：InteractionPreset.listen 的触发函数。子类必须覆写。
func interact(_source: Character, _target) -> Array:
    return []

## 攻击比防御高(isMax=True)，则降低(isPositive=False)生命，降低值为攻击防御差值
## 被谁用：Interaction_Attack.interact。
func attack(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true
    var s_dynamic=true; var c_dynamic=true; var t_dynamic=false
    var s_before=false; var c_before=false; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    var s_consume=true; var c_consume=true; var t_consume=false
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type, s_consume, c_consume, t_consume)

## 治疗量比生命高(isMax=True)，则增加(isPositive=False)生命，增加值为治疗生命差值
## 被谁用：Interaction_Heal.interact。
func heal(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = true; var isMax = true
    var s_dynamic=true; var c_dynamic=true; var t_dynamic=false
    var s_before=false; var c_before=false; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    var s_consume=true; var c_consume=false; var t_consume=false
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type, s_consume, c_consume, t_consume)

## 治疗后，计算治疗前后血量差值，治疗量比生命高(isMax=True)，则降低(isPositive=False)生命，增加值为治疗生命差值
## 被谁用：Interaction_CostHeal.interact。
func cost(char_source: Character, char_compare: Character, char_target: Character, source_attr_category: String, compare_attr_category: String, target_attr_category: String) -> ChangeResult:
    var isPositive = false; var isMax = true; 
    var s_dynamic=false; var c_dynamic=false; var t_dynamic=false
    var s_before=false; var c_before=true; var t_before=false
    var s_value_type=Enums.ValueType.CUR; var c_value_type=Enums.ValueType.CUR; var t_value_type=Enums.ValueType.CUR
    var s_consume=false; var c_consume=false; var t_consume=false
    return impact(char_source, char_compare, char_target, source_attr_category, compare_attr_category, target_attr_category, isPositive, isMax, s_dynamic, c_dynamic, t_dynamic, s_before, c_before, t_before, s_value_type, c_value_type, t_value_type, s_consume, c_consume, t_consume)


# var isPositive: bool
# 在有比较对象B时(isMyself)，    最终取值有取最大值或正常输出，此时is_max表示取最大值
# 在无比较对象B时(not isMyself)，最终取值有取最大值或取最小值，此时is_max表示取最大值
# var isMax: bool    
## 属性交互的公共实现：取三方（影响者/比较对象/受影响者）的属性值 → 算变化量（差值，可只取正）→ 方向（正/反）
## → 作用到受影响者的 CUR 上并返回 ChangeResult；各 *_dynamic / *_from_before / *_consume 决定取值口径与是否结算 buff。
## 被谁用：attack / heal / cost（三种套路只是这里的参数预设）。
func impact(
        char_source: Character, char_compare: Character, char_target: Character,
        source_attr_category: String, compare_attr_category: String, target_attr_category: String,
        isPositive: bool, isMax: bool, 
        source_dynamic: bool=false, compare_dynamic: bool=false, target_dynamic: bool=false,
        source_from_before: bool=false, compare_from_before: bool=false, target_from_before: bool=false, 
        source_value_type:=Enums.ValueType.CUR, compare_value_type=Enums.ValueType.CUR, target_value_type:=Enums.ValueType.CUR,
        source_consume: bool=false, compare_consume: bool=false, target_consume: bool=false
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
    if source_consume:
        attr_source.consume_buffs(source_attr_category, source_value_type)
    if compare_consume:
        attr_compare.consume_buffs(compare_attr_category, compare_value_type)
    if target_consume:
        attr_target.consume_buffs(target_attr_category, target_value_type)

    # 关系
    # 计算变化量，是否为单面变化(非负数)
    var offset = max(value_source - value_compare, 0) if isMax else value_source - value_compare
    # 计算变化方向，为正向或反向
    offset = offset if isPositive else -offset
    var level_cur_new = value_target + offset 

    return attr_target.set_level_cur(target_attr_category, level_cur_new, name, char_source)

    
## 成长（练习）：以"当前值到基准值的距离"决定本次增幅，作用到该属性的 CUR 上。
## 被谁用：Interaction_Practice.interact。
func practice(char_: Character, attr_category: String) -> ChangeResult:
    var attr = char_.attrs
    var level_cur = attr.get_(attr_category, Enums.ValueType.CUR)
    var level_base = attr.get_(attr_category, Enums.ValueType.BASE)
    var level_multiplier = attr.get_(attr_category, Enums.ValueType.MULTIPLIER)
    attr.consume_buffs(attr_category, Enums.ValueType.CUR)
    attr.consume_buffs(attr_category, Enums.ValueType.BASE)
    attr.consume_buffs(attr_category, Enums.ValueType.MULTIPLIER)

    var center_distance = level_base - level_cur
    var level_cur_practice = attr.get_dynamic_value(level_cur, level_multiplier, center_distance, true, false)
    # print(char_.name, " practice: ", attr_category, " cur:", level_cur, " base: ", level_base, " multiplier: ", level_multiplier, " center_distance: ", center_distance, " cur_practice: ", level_cur_practice)
    return attr.set_level_cur(attr_category, level_cur_practice, name, char_)
