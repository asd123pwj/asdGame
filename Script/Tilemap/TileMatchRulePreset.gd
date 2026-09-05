class_name TileMatchRulePreset
extends PresetRegister

# 匹配邻居的类型
# 1=空 2=非空 3=非空但规则不同 4=非空且规则相同
enum RuleType { IS_NULL, NOT_NULL, DIFF_RULE, SAME_RULE }

# 规则名（与 TileNameRulePreset 同名关联，tiles_name 已迁移到 TileNameRulePreset）
var name: String
# 匹配矩阵：Array of [tile_name, 匹配矩阵]（中心 9，空 1，非空 2，规则不同 3，规则相同 4，无要求 0）
var match_matrix: Array = []
# 匹配时检查的邻居偏移列表（左右四格 + 上下各一格）
var reference_pos: Array[Vector2i] = []
# 匹配规则：Array of [sub_ID(String), Dictionary[RuleType, Array[Vector2i]]]
var match_rules: Array = []

static var _we: Dictionary[String, TileMatchRulePreset] = {}


func _init(rule_name: String, match_matrix: Array) -> void:
    _we[rule_name] = self
    self.name = rule_name
    self.match_matrix = match_matrix
    build_from_matrix()


static func get_(rule_name: String) -> TileMatchRulePreset:
    return _we.get(rule_name)


# 从 match_matrix 生成 reference_pos 和 match_rules
# 矩阵以值为 9 的位置为中心计算偏移，支持任意大小（可去零行/列）
func build_from_matrix() -> void:
    reference_pos = _collect_reference_pos()
    match_rules = _rules_from_matrix()


# 查找矩阵中值为 9 的中心位置
func _find_center(matrix: Array) -> Vector2i:
    for row in matrix.size():
        var mrow: Array = matrix[row]
        for col in mrow.size():
            if mrow[col] == 9:
                return Vector2i(row, col)
    # 未找到 9 属于规则定义错误，直接报错
    push_error("[TileMatchRulePreset] ", name, " 的匹配矩阵中找不到中心值 9，矩阵=", matrix)
    return Vector2i(-1, -1)


# 收集所有非 0 非 9 位置的偏移作为 reference_pos
func _collect_reference_pos() -> Array[Vector2i]:
    var pos: Array[Vector2i] = []
    var seen: Dictionary = {}
    for entry in match_matrix:
        var matrix: Array = entry[1]
        var center := _find_center(matrix)
        for row in matrix.size():
            var mrow: Array = matrix[row]
            for col in mrow.size():
                var v: int = mrow[col]
                if v != 0 and v != 9:
                    var offset := _cell_to_offset(row, col, center)
                    if not seen.has(offset):
                        seen[offset] = true
                        pos.append(offset)
    return pos


# 从 match_matrix 生成 match_rules（转成 vector2 偏移，遍历更快且丢弃 0 冗余）
func _rules_from_matrix() -> Array:
    var rules: Array = []
    for entry in match_matrix:
        var rule_name: String = entry[0]
        var matrix: Array = entry[1]
        var center := _find_center(matrix)
        var type_map: Dictionary = {
            RuleType.IS_NULL: [],
            RuleType.NOT_NULL: [],
            RuleType.DIFF_RULE: [],
            RuleType.SAME_RULE: [],
        }
        for row in matrix.size():
            var mrow: Array = matrix[row]
            for col in mrow.size():
                var v: int = mrow[col]
                var rule_type: int = -1
                if v == 1:
                    rule_type = RuleType.IS_NULL
                elif v == 2:
                    rule_type = RuleType.NOT_NULL
                elif v == 3:
                    rule_type = RuleType.DIFF_RULE
                elif v == 4:
                    rule_type = RuleType.SAME_RULE
                if rule_type >= 0:
                    var arr: Array = type_map[rule_type]
                    arr.append(_cell_to_offset(row, col, center))
        rules.append([rule_name, type_map])
    return rules


# 矩阵单元 (row, col) 以中心(center_row, center_col)转偏移 (x, y)
# 行 0=上（中心行上方 y+1），中心列右边 x 正
func _cell_to_offset(row: int, col: int, center: Vector2i) -> Vector2i:
    return Vector2i(col - center.y, center.x - row)


# 根据邻居情况匹配，返回命中的 tile 名称（sub_ID）
# 无匹配说明规则表缺漏（应有 FULL 兜底），直接报错
func match(neighbor_map: Dictionary) -> String:
    for rule in match_rules:
        if _is_match(rule, neighbor_map):
            return rule[0]
    push_error("[TileMatchRulePreset] ", name, " 匹配无结果，neighbor_map=", neighbor_map)
    return ""


# 判断单个规则是否匹配：规则内所有 (type, offsets) 都满足
func _is_match(rule: Array, neighbor_map: Dictionary) -> bool:
    for rule_type in rule[1]:
        var offsets: Array = rule[1][rule_type]
        for offset in offsets:
            if not _match_single(rule_type, offset, neighbor_map):
                return false
    return true


# 判断单个邻居偏移是否满足类型要求。
# neighbor_map 值：1=空，3=非空但规则不同，4=非空且规则相同。
func _match_single(rule_type: int, offset: Vector2i, neighbor_map: Dictionary) -> bool:
    var v: int = neighbor_map.get(offset, RuleType.IS_NULL)
    match rule_type:
        RuleType.IS_NULL:
            return v == RuleType.IS_NULL
        RuleType.NOT_NULL:
            return v != RuleType.IS_NULL
        RuleType.DIFF_RULE:
            return v == RuleType.DIFF_RULE
        RuleType.SAME_RULE:
            return v == RuleType.SAME_RULE
    return false
