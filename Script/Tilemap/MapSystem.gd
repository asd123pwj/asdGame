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
    # 循环1：记录待放置的 tile（place 用 tile_name 选择 tile，找不到回退到 (0,0) 位置的 tile）
    for i in range(0, 4):
        for j in range(-6, -10, -1):
            place(0, Enums.LayerType.MIDDLE, i, j, "P3D", "FULL")
            place(0, Enums.LayerType.MIDDLE, i, j+5, "White Wall", "FULL")
            place(0, Enums.LayerType.MIDDLE, i+1, j+5+1, "透明玻璃", "FULL")
            place(0, Enums.LayerType.MIDDLE, i+5+1, j+5+1, "完整玻璃", "FULL")
            place(0, Enums.LayerType.MIDDLE, i+10+1, j+5+1, "完整玻璃-反", "FULL")
    # 循环2：根据 map_content 放置 tile 和 P3D
    layer.build()


# 放置 tile/P3D：layer_id 世界层号，layer_type 对应六种子层类型之一
# tile_name 用匹配规则的 tiles_name 中的名称选择 tile；找不到则提示并回退到 (0,0) 位置的 tile
static func place(layer_id: int, layer_type: int, x: int, y: int,
        source_name: String, tile_name: String) -> void:
    if not TileSetPreset.has_tile_name(source_name, tile_name):
        push_error("MapSystem.place: 在 source[", source_name, "] 中找不到 tile 名称: ", tile_name,
            "，回退到 (0,0) 位置的 tile")
        tile_name = TileSetPreset.get_default_tile_name(source_name)
    var tile_id := TileSetPreset.get_or_register_tile_id(source_name, tile_name)
    layers[layer_id].place(layer_type, x, y, tile_id)


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]
