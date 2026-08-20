class_name TMapSys
extends RefCounted

static var top_map: Node2D = Node2D.new()
static var maps: Dictionary[int, TileMapLayer] = {}

func _init() -> void:
    Sys.sys.add_child(top_map)
    create_tilemap(0)
    for i in range(1, 10):
        for j in range(1, 10):
            place_tile(0, i, j, "白墙青瓦")
            place_tile(0, i+20, j, "White Wall")


static func place_tile(id: int, x: int, y: int, source_name: String) -> void:
    var source_id: int = TileSetPreset.get_source_id(source_name)
    maps[id].set_cell(Vector2i(x, y), source_id, Vector2i(2, 0))

static func create_tilemap(id: int) -> void:
    var tileset: TileSet = TileSetPreset.tileset

    maps[id] = TileMapLayer.new()
    maps[id].tile_set = TileSetPreset.tileset
    top_map.add_child(maps[id])