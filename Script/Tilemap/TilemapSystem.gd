class_name TMapSys
extends RefCounted

static var maps_parent_node: Node2D = Node2D.new()
static var maps: Dictionary[int, TileMapLayer] = {}
static var maps_canvas: Dictionary[int, CanvasLayer] = {}
const P3D_OFFSET := Vector2(8, 8)

func _init() -> void:
    Sys.sys.add_child(maps_parent_node)

    var id = map_layer_to_id(0, Enums.LayerType.MIDDLE)
    create_tilemap(id)
    create_P3D_canvas(id-1)
    for i in range(1, 10):
        for j in range(1, 10):
            place_tile_with_P3D(id, i, j, "P3D")
            place_tile_with_P3D(id, i+10, j, "White Wall")
            place_tile_with_P3D(id, i, j+10, "透明玻璃")


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]

static func place_tile_with_P3D(id: int, x: int, y: int, source_name: String) -> void:
    place_tile(id, x, y, source_name)
    place_p3d_sprite(id-1, x, y, source_name)

static func place_tile(id: int, x: int, y: int, source_name: String) -> void:
    var source_id: int = TileSetPreset.get_source_id(source_name)
    maps[id].set_cell(Vector2i(x, y), source_id, Vector2i(0, 2))


static func place_p3d_sprite(id: int, x: int, y: int, source_name: String) -> void:
    var sprite := TileSetPreset.create_p3d_sprite(source_name, Vector2i(0, 2))
    # 定位到格子左上角，并补偿伪3D内容在瓦片内的偏移
    sprite.position = Vector2(x * 32, y * 32) - P3D_OFFSET
    sprite.name = str(x) + "," + str(y)
    sprite.z_index = x - y
    maps_canvas[id].add_child(sprite)

static func create_P3D_canvas(id: int) -> void:
    maps_canvas[id] = CanvasLayer.new()
    maps_canvas[id].name = "Canvas " + map_id_to_name(id)
    maps_canvas[id].layer = id
    maps_parent_node.add_child(maps_canvas[id])

static func create_tilemap(id: int) -> void:
    var tileset: TileSet = TileSetPreset.tileset
    maps[id] = TileMapLayer.new()
    maps[id].name = map_id_to_name(id)
    # maps[id].collision_visibility_mode = TileMapLayer.DebugVisibilityMode.DEBUG_VISIBILITY_MODE_FORCE_SHOW
    maps[id].tile_set = TileSetPreset.tileset
    maps_canvas[id] = CanvasLayer.new()
    maps_canvas[id].name = "Canvas " + map_id_to_name(id)
    maps_canvas[id].layer = id
    maps_canvas[id].add_child(maps[id])
    maps_parent_node.add_child(maps_canvas[id])