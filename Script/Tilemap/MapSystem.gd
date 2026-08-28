class_name MapSys
extends RefCounted

static var maps_parent_node: Node2D = Node2D.new()
# 世界层：layer_id -> MapLayer（每个 MapLayer 管理六个子层）
static var layers: Dictionary[int, MapLayer] = {}
# P3D 擦除掩码 shader（供 MapLayer 使用），通过 ShaderManager 按文件名访问
static var erase_shader: Shader = ShaderManager.get_shader("p3d_mask")


func _init() -> void:
    Sys.sys.add_child(maps_parent_node)

    # 创建一个世界层 layer 0
    var layer := MapLayer.new(0, maps_parent_node)
    layers[0] = layer
    # 循环1：记录待放置的 tile（只指定 source，具体 tile 由 build() 自动匹配）
    place(0, Enums.LayerType.PLANT, 1, -15, "水稻")
    place(0, Enums.LayerType.PLANT, 2, -15, "水稻")
    place(0, Enums.LayerType.PLANT, 4, -15, "水稻")
    place(0, Enums.LayerType.PLANT, 5, -15, "水稻")
    place(0, Enums.LayerType.PLANT, 6, -15, "水稻")
    place(0, Enums.LayerType.MIDDLE, 7, -15, "泥土")
    place(0, Enums.LayerType.PLANT, 8, -15, "水稻")

    for i in range(1, 10):
        var j = -16
        place(0, Enums.LayerType.MIDDLE, i+9, j+1, "白墙青瓦")
        place(0, Enums.LayerType.MIDDLE, i, j, "泥土")
        place(0, Enums.LayerType.MIDDLE, i+9, j, "White Wall")
        place(0, Enums.LayerType.MIDDLE, i+18, j, "透明玻璃")
        place(0, Enums.LayerType.MIDDLE, i, j-1, "泥土")
        place(0, Enums.LayerType.MIDDLE, i+9, j-1, "White Wall")
        place(0, Enums.LayerType.MIDDLE, i+18, j-1, "透明玻璃")

    for i in range(0, 4):
        for j in range(-6, -10, -1):
            # place(0, Enums.LayerType.MIDDLE, i, j, "P3D")
            place(0, Enums.LayerType.MIDDLE, i, j+5, "White Wall")
            place(0, Enums.LayerType.MIDDLE, i+1, j+5+1, "透明玻璃")
            # place(0, Enums.LayerType.MIDDLE, i+5+1, j+5+1, "完整玻璃")
            # place(0, Enums.LayerType.MIDDLE, i+10+1, j+5+1, "完整玻璃-反")
    # 循环2：根据 map_content 放置 tile 和 P3D
    layer.build()


# 放置 tile/P3D：layer_id 世界层号，layer_type 对应子层类型
# tile_name 为空时使用默认占位 tile，build() 时按邻居自动匹配合适的 tile_name；
# 指定 tile_name（如 "FULL" 或 auto_expand 的 "1_1_1"）时该位置固定为该 tile，不参与匹配。
static func place(layer_id: int, layer_type: int, x: int, y: int, source_name: String,
        tile_name: String = "") -> void:
    var target_name := tile_name if not tile_name.is_empty() else TileSetPreset.get_default_tile_name(source_name)
    if target_name.is_empty():
        push_error("MapSystem.place: source[", source_name,
            "] 未配置匹配规则，无法确定占位 tile，请配置 tile_match_rule_name 或指定 tile_name")
        return
    var tile_id := TileSetPreset.get_or_register_tile_id(source_name, target_name)
    layers[layer_id].place(layer_type, x, y, tile_id, not tile_name.is_empty())


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]
