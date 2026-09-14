class_name MapPlaceRulePreset
extends PresetRegister
## 放置需求预设：一条"相对当前格，某层的某个位置必须有/不能有某个 tag"的检查项。
## 多条需求组合起来就是一个 source 的放置兼容规则（见 check_compatible）。
## 被谁用：TileSetPreset.get_place_rule_names（source 上配的规则名）、MapSys.place（放置前检查）。

# 单个命名的放置需求（不再用九宫格，每个需求检查一个相对位置）：
#   [name, offset_x, offset_y, layer, tag, must_have]
#   name     : 需求名
#   offset_x : 检索位置相对当前格的 x 偏移
#   offset_y : 检索位置相对当前格的 y 偏移（逻辑坐标 y 向上为正）
#   layer    : 要检查的层（Enums.LayerType）
#   tag      : 要检查的 tag（匹配该格 tile 的 tile_name 或 source_name）
#   must_have: true=该层该位置必须存在该 tag；false=必须不存在
var name: String
var offset: Vector2i
var layer: int
var tag: String
var must_have: bool

## 全部预设：名 -> 实例。被谁用：get_。
static var _we: Dictionary[String, MapPlaceRulePreset] = {}


## 注册一条放置需求。被谁用：PresetRegister 的注册流程。
func _init(name: String, offset_x: int, offset_y: int, layer: int, tag: String, must_have: bool) -> void:
    _we[name] = self
    self.name = name
    self.offset = Vector2i(offset_x, offset_y)
    self.layer = layer
    self.tag = tag
    self.must_have = must_have


## 按名取需求（没有返回 null）。被谁用：check_compatible。
static func get_(name: String) -> MapPlaceRulePreset:
    return _we.get(name)


# 判断该层该格是否有放置空间。
# 若该格当前已放置了 Enums.layer_incompatible[target_layer] 中任一层的物体（用户手动指定的排除层，含自身层），则无空间返回 false。
# query_tile: Callable(layer:int, x:int, y:int) -> bool  该层该格是否已有物体
## 被谁用：MapSys.place（锚点/组内其它位置的"有没有空间"检查）。
static func check_can_place(target_layer: int, x: int, y: int, query_tile: Callable) -> bool:
    for layer in Enums.layer_incompatible.get(target_layer, []):
        if query_tile.call(layer, x, y):
            return false
    return true


# 判断该位置是否兼容放置：遍历要检查的一组命名需求（and，全部满足才兼容）。
# rule_names: 使用的命名需求列表
# query_tag: Callable(layer:int, x:int, y:int, tag:String) -> bool  该层该格 tile 是否具有 tag
## 被谁用：MapSys.place（force_compatible 为 false 时）；source 没配规则时传空数组直接通过。
static func check_compatible(rule_names: Array, x: int, y: int, query_tag: Callable) -> bool:
    for rname in rule_names:
        var rule: MapPlaceRulePreset = get_(rname)
        if rule == null:
            push_error("[MapPlaceRulePreset] 找不到放置需求: ", rname)
            return false
        var has: bool = query_tag.call(rule.layer, x + rule.offset.x, y + rule.offset.y, rule.tag)
        if has != rule.must_have:
            return false
    return true
