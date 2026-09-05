class_name TileNameRulePreset
extends PresetRegister

# 匹配规则名（与 TileMatchRulePreset 同名关联）
var name: String
# 各位置 tile 的名称矩阵（source 分片后的 tile 名称，也是匹配规则检索的名称）。
# 元素可为 String（该位置 tile 名）或 Array（[组名, [H, W]]，一组多格共用组名）。
var tiles_name: Array = []

static var _we: Dictionary[String, TileNameRulePreset] = {}
# 每格原始尺寸矩阵：rule_name -> Array[Array]（每格 Vector2i(w,h)，未配置默认 48x48）。供素材预处理成 48x48 使用。
static var _cell_sizes: Dictionary = {}


func _init(rule_name: String, tiles_name: Array) -> void:
    _we[rule_name] = self
    self.name = rule_name
    self.tiles_name = tiles_name
    _parse_cell_sizes(rule_name, tiles_name)


# 解析 tiles_name 每格尺寸：元素为 [名称, [H, W]] 时尺寸为 (W,H)，纯字符串默认 48x48。
static func _parse_cell_sizes(rule_name: String, tiles_name: Array) -> void:
    var sizes: Array = []
    for row in tiles_name:
        var row_sizes: Array = []
        for cell in row:
            var size := SysCfg.REGION_SIZE
            if cell is Array:
                var cell_arr: Array = cell
                if cell_arr.size() > 1 and cell_arr[1] is Array:
                    var size_arr: Array = cell_arr[1]
                    if size_arr.size() >= 2:
                        size = Vector2i(size_arr[1], size_arr[0])  # [H,W] -> (w,h)
            row_sizes.append(size)
        sizes.append(row_sizes)
    _cell_sizes[rule_name] = sizes


# 获取某规则的每格尺寸矩阵（二维，每格 Vector2i(w,h)）
static func get_cell_sizes(rule_name: String) -> Array[Array]:
    var sizes: Array = _cell_sizes.get(rule_name, [])
    var result: Array[Array] = []
    for row in sizes:
        result.append(row)
    return result


static func get_(rule_name: String) -> TileNameRulePreset:
    return _we.get(rule_name)
