class_name BlockRule
extends TileMatchRuleBase


func _init() -> void:
    tiles_name = [
        ["M", "L3210", "R3210", "DL3210", "DR3210"],
        ["DM", "L10", "L21", "L32", "L43"],
        ["FULL", "R43", "R32", "R21", "R10"],
    ]
    reference_pos = [
        Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
        Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
        Vector2i(0, -1),
    ]
    match_rules = _build_rules()


func _build_rules() -> Array:
    var rules: Array = []
    rules.append(_rule("L43", {
        RuleType.IS_NULL: [Vector2i(-4, 0), Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1)],
        RuleType.NOT_NULL: [Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
    }))
    rules.append(_rule("L32", {
        RuleType.IS_NULL: [Vector2i(-3, 0), Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1)],
        RuleType.NOT_NULL: [Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    }))
    rules.append(_rule("L32", {
        RuleType.IS_NULL: [Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(3, 0)],
        RuleType.NOT_NULL: [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0)],
    }))
    rules.append(_rule("L32", {
        RuleType.IS_NULL: [Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1)],
        RuleType.NOT_NULL: [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
    }))
    rules.append(_rule("L32", {
        RuleType.IS_NULL: [Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(4, 0)],
        RuleType.NOT_NULL: [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    }))
    rules.append(_rule("L21", {
        RuleType.IS_NULL: [Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
        RuleType.NOT_NULL: [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
    }))
    rules.append(_rule("L10", {
        RuleType.IS_NULL: [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1)],
        RuleType.NOT_NULL: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    }))
    rules.append(_rule("L3210", {
        RuleType.IS_NULL: [Vector2i(-1, 0), Vector2i(0, 1)],
        RuleType.NOT_NULL: [Vector2i(1, 0)],
    }))
    rules.append(_rule("M", {
        RuleType.IS_NULL: [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)],
    }))
    rules.append(_rule("R43", {
        RuleType.IS_NULL: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 0)],
        RuleType.NOT_NULL: [Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    }))
    rules.append(_rule("R32", {
        RuleType.IS_NULL: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 0)],
        RuleType.NOT_NULL: [Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0)],
    }))
    rules.append(_rule("R32", {
        RuleType.IS_NULL: [Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)],
        RuleType.NOT_NULL: [Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0)],
    }))
    rules.append(_rule("R32", {
        RuleType.IS_NULL: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)],
        RuleType.NOT_NULL: [Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(1, 0)],
    }))
    rules.append(_rule("R32", {
        RuleType.IS_NULL: [Vector2i(-4, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)],
        RuleType.NOT_NULL: [Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0)],
    }))
    rules.append(_rule("R21", {
        RuleType.IS_NULL: [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)],
        RuleType.NOT_NULL: [Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0)],
    }))
    rules.append(_rule("R10", {
        RuleType.IS_NULL: [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 0)],
        RuleType.NOT_NULL: [Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0)],
    }))
    rules.append(_rule("R3210", {
        RuleType.IS_NULL: [Vector2i(0, 1), Vector2i(1, 0)],
        RuleType.NOT_NULL: [Vector2i(-1, 0)],
    }))
    rules.append(_rule("DL3210", {
        RuleType.IS_NULL: [Vector2i(-1, 0), Vector2i(0, -1)],
        RuleType.NOT_NULL: [Vector2i(0, 1), Vector2i(1, 0)],
    }))
    rules.append(_rule("DR3210", {
        RuleType.IS_NULL: [Vector2i(0, -1), Vector2i(1, 0)],
        RuleType.NOT_NULL: [Vector2i(-1, 0), Vector2i(0, 1)],
    }))
    rules.append(_rule("DM", {
        RuleType.IS_NULL: [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)],
        RuleType.NOT_NULL: [Vector2i(0, 1)],
    }))
    rules.append(_rule("FULL", {}))
    return rules


# 构造单条规则：[sub_ID, Dictionary[RuleType, Array[Vector2i]]]
func _rule(sub_id: String, rule_map: Dictionary) -> Array:
    return [sub_id, rule_map]
