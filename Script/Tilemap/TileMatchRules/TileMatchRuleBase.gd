# class_name TileMatchRuleBase
# extends RefCounted

# # 匹配邻居的类型
# enum RuleType { IS_NULL, NOT_NULL }

# # 匹配规则名（类名）
# @warning_ignore("unsafe_method_access")
# var name: String = get_script().get_global_name()
# # 各位置 tile 的名称矩阵（source 分片后的 tile 名称，也是匹配规则检索的名称）
# var tiles_name: Array[Array] = []
# # 匹配矩阵：Array of [tile_name, 3x9 匹配矩阵]（中心 9，空 1，非空 2，不匹配 0）
# # 用 Array 而非 Dictionary，因为同一 tile_name 可能有多个匹配变体（如 L32/R32）
# var match_matrix: Array = []
# # 匹配时检查的邻居偏移列表（左右四格 + 上下各一格）
# var reference_pos: Array[Vector2i] = []
# # 匹配规则：Array of [sub_ID(String), Dictionary[RuleType, Array[Vector2i]]]
# var match_rules: Array = []


# # 从 match_matrix 生成 reference_pos 和 match_rules（子类在 _init 中定义好 match_matrix 后调用）
# # 矩阵以值为 9 的位置为中心计算偏移，支持任意大小（可去零行/列）
# func build_from_matrix() -> void:
#     reference_pos = _collect_reference_pos()
#     match_rules = _rules_from_matrix()


# # 查找矩阵中值为 9 的中心位置，返回 [center_row, center_col]
# func _find_center(matrix: Array) -> Vector2i:
#     for row in matrix.size():
#         var mrow: Array = matrix[row]
#         for col in mrow.size():
#             if mrow[col] == 9:
#                 return Vector2i(row, col)
#     # 未找到 9 属于规则定义错误，直接报错
#     push_error("[TileMatchRulePreset] ", name, " 的匹配矩阵中找不到中心值 9，矩阵=", matrix)
#     return Vector2i(-1, -1)


# # 收集所有非 0 非 9 位置的偏移作为 reference_pos
# func _collect_reference_pos() -> Array[Vector2i]:
#     var pos: Array[Vector2i] = []
#     var seen: Dictionary = {}
#     for entry in match_matrix:
#         var matrix: Array = entry[1]
#         var center := _find_center(matrix)
#         for row in matrix.size():
#             var mrow: Array = matrix[row]
#             for col in mrow.size():
#                 var v: int = mrow[col]
#                 if v != 0 and v != 9:
#                     var offset := _cell_to_offset(row, col, center)
#                     if not seen.has(offset):
#                         seen[offset] = true
#                         pos.append(offset)
#     return pos


# # 从 match_matrix 生成 match_rules
# func _rules_from_matrix() -> Array:
#     var rules: Array = []
#     for entry in match_matrix:
#         var rule_name: String = entry[0]
#         var matrix: Array = entry[1]
#         var center := _find_center(matrix)
#         var is_null: Array = []
#         var not_null: Array = []
#         for row in matrix.size():
#             var mrow: Array = matrix[row]
#             for col in mrow.size():
#                 var v: int = mrow[col]
#                 if v == 1:
#                     is_null.append(_cell_to_offset(row, col, center))
#                 elif v == 2:
#                     not_null.append(_cell_to_offset(row, col, center))
#         rules.append([rule_name, {
#             RuleType.IS_NULL: is_null,
#             RuleType.NOT_NULL: not_null,
#         }])
#     return rules


# # 矩阵单元 (row, col) 以中心(center_row, center_col)转偏移 (x, y)
# # 行 0=上（中心行上方 y+1），中心列右边 x 正
# func _cell_to_offset(row: int, col: int, center: Vector2i) -> Vector2i:
#     return Vector2i(col - center.y, center.x - row)


# # 根据邻居情况匹配，返回命中的 tile 名称（sub_ID）
# # 无匹配说明规则表缺漏（应有 FULL 兜底），直接报错
# # neighbor_map: Dictionary[Vector2i, bool]（offset -> 该邻居是否非空）
# func match(neighbor_map: Dictionary) -> String:
#     for rule in match_rules:
#         if _is_match(rule, neighbor_map):
#             return rule[0]
#     push_error("[TileMatchRulePreset] ", name, " 匹配无结果，neighbor_map=", neighbor_map)
#     return ""


# # 判断单个规则是否匹配：规则内所有 (type, offsets) 都满足
# func _is_match(rule: Array, neighbor_map: Dictionary) -> bool:
#     for rule_type in rule[1]:
#         var offsets: Array = rule[1][rule_type]
#         for offset in offsets:
#             if not _match_single(rule_type, offset, neighbor_map):
#                 return false
#     return true


# # 判断单个邻居偏移是否满足类型要求
# func _match_single(rule_type: int, offset: Vector2i, neighbor_map: Dictionary) -> bool:
#     var not_empty: bool = neighbor_map.get(offset, false)
#     if rule_type == RuleType.IS_NULL:
#         return not not_empty
#     else:  # NOT_NULL
#         return not_empty
