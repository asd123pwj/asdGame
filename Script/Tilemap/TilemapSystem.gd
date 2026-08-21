class_name TMapSys
extends RefCounted

static var top_map: Node2D = Node2D.new()
static var maps: Dictionary[int, TileMapLayer] = {}

func _init() -> void:
    Sys.sys.add_child(top_map)
    for i in range(0, 1):
        for layer_type in [Enums.LayerType.MIDDLE, Enums.LayerType.MIDDLE_P3D]:
            create_tilemap(map_layer_to_id(i, layer_type))
    var id = map_layer_to_id(0, Enums.LayerType.MIDDLE)
    create_tilemap(id)
    for i in range(1, 10):
        for j in range(1, 10):
            place_tile_with_P3D(id, i, j, "P3D")
            place_tile_with_P3D(id, i+20, j, "White Wall")


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func place_tile_with_P3D(id: int, x: int, y: int, source_name: String) -> void:
    # 正常地图
    var source_id: int = TileSetPreset.get_source_id(source_name)
    maps[id].set_cell(Vector2i(x, y), source_id, Vector2i(0, 2))
    # 伪3D地图为正常层-1
    source_id = TileSetPreset.get_source_id_P3D(source_name)
    maps[id-1].set_cell(Vector2i(x, y), source_id, Vector2i(0, 2))


static func place_tile(id: int, x: int, y: int, source_name: String) -> void:
    var source_id: int = TileSetPreset.get_source_id(source_name)
    maps[id].set_cell(Vector2i(x, y), source_id, Vector2i(0, 2))

static func create_tilemap(id: int) -> void:
    var tileset: TileSet = TileSetPreset.tileset
    maps[id] = TileMapLayer.new()
    # maps[id].collision_visibility_mode = TileMapLayer.DebugVisibilityMode.DEBUG_VISIBILITY_MODE_FORCE_SHOW
    maps[id].tile_set = TileSetPreset.tileset
    top_map.add_child(maps[id])