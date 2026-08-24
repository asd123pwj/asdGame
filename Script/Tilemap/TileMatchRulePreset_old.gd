# class_name TileMatchRulePreset
# extends RefCounted

# # 规则表：规则名 -> 规则实例
# static var rules: Dictionary = {}


# # 加载所有规则（暂时写死加载 BlockRule，后续可转为 json 配置）
# static func load_all() -> void:
#     if not rules.is_empty():
#         return
#     _register(BlockRule.new())


# static func _register(rule: TileMatchRuleBase) -> void:
#     rules[rule.name] = rule


# # 按规则名获取规则实例，不存在返回 null
# static func get_rule(rule_name: String) -> TileMatchRuleBase:
#     load_all()
#     return rules.get(rule_name)
