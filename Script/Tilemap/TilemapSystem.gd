class_name TMapSys
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
    # 循环1：记录待放置的 tile（place 会同时放置配套的 tile 和 P3D）
    for i in range(0, 4):
        for j in range(0, 4):
            place(0, Enums.LayerType.MIDDLE, i, j, "P3D", Vector2i(0, 2))
            place(0, Enums.LayerType.MIDDLE, i+5, j+1, "White Wall", Vector2i(0, 2))
            place(0, Enums.LayerType.MIDDLE, i+1, j+5+1, "透明玻璃", Vector2i(0, 2))
            place(0, Enums.LayerType.MIDDLE, i+5+1, j+5+1, "完整玻璃", Vector2i(0, 2))
            place(0, Enums.LayerType.MIDDLE, i+10+1, j+5+1, "完整玻璃-反", Vector2i(0, 2))
    # 循环2：根据 map_content 放置 tile 和 P3D
    layer.build()


# 放置 tile/P3D：layer_id 世界层号，layer_type 对应六种子层类型之一
static func place(layer_id: int, layer_type: int, x: int, y: int,
        source_name: String, atlas_coords: Vector2i) -> void:
    var tile_id := TileSetPreset.get_or_register_tile_id(source_name, atlas_coords)
    layers[layer_id].place(layer_type, x, y, tile_id)


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]
