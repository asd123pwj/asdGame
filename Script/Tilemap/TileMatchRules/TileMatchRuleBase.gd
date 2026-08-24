class_name TileMatchRuleBase
extends RefCounted

# 匹配邻居的类型
enum RuleType { IS_NULL, NOT_NULL }

# 匹配规则名（类名）
@warning_ignore("unsafe_method_access")
var name: String = get_script().get_global_name()
# 各位置 tile 的名称矩阵（source 分片后的 tile 名称，也是匹配规则检索的名称）
var tiles_name: Array[Array] = []
# 匹配时检查的邻居偏移列表（左右四格 + 上下各一格）
var reference_pos: Array[Vector2i] = []
# 匹配规则：Array of [sub_ID(String), Dictionary[RuleType, Array[Vector2i]]]
var match_rules: Array = []


# 根据邻居情况匹配，返回命中的 tile 名称（sub_ID），无匹配返回 ""
# neighbor_map: Dictionary[Vector2i, bool]（offset -> 该邻居是否非空）
func match(neighbor_map: Dictionary) -> String:
    for rule in match_rules:
        if _is_match(rule, neighbor_map):
            return rule[0]
    return ""


# 判断单个规则是否匹配：规则内所有 (type, offsets) 都满足
func _is_match(rule: Array, neighbor_map: Dictionary) -> bool:
    for rule_type in rule[1]:
        var offsets: Array = rule[1][rule_type]
        for offset in offsets:
            if not _match_single(rule_type, offset, neighbor_map):
                return false
    return true


# 判断单个邻居偏移是否满足类型要求
func _match_single(rule_type: int, offset: Vector2i, neighbor_map: Dictionary) -> bool:
    var not_empty: bool = neighbor_map.get(offset, false)
    if rule_type == RuleType.IS_NULL:
        return not not_empty
    else:  # NOT_NULL
        return not_empty
