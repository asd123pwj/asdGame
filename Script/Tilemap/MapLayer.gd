class_name MapLayer
extends RefCounted

# 子层 id = layer_id * COUNT + layer_type
static func sub_layer_id(layer_id: int, layer_type: int) -> int:
    return layer_id * Enums.LayerType.COUNT + layer_type


# 判断 layer_type 是否为 P3D 类型（偶数为 P3D：BACK_P3D/MIDDLE_P3D/FRONT_P3D）
static func is_p3d_type(layer_type: int) -> bool:
    return layer_type % 2 == 0


# 映射 layer_type 到组 key（普通类型：BACK/MIDDLE/FRONT），tile 与 P3D 配套共用
static func group_key(layer_type: int) -> int:
    return layer_type + 1 if layer_type % 2 == 0 else layer_type


var _layer_id: int
var _parent: Node2D
# 子层 id -> TileMapLayer（普通类型）和 CanvasLayer（P3D 类型）
var _tile_maps: Dictionary[int, TileMapLayer] = {}
var _p3d_canvases: Dictionary[int, CanvasLayer] = {}
# 多区块（Godot 不支持三层嵌套类型化，只写前两层，完整结构见注释）
# Dictionary[int /* 组key: BACK/MIDDLE/FRONT */, Dictionary[Vector2i /* 区块 */, Array /* 16x16 矩阵(int tile id) */]]
var _map_content: Dictionary[int, Dictionary] = {}
# 记录放置顺序（Godot 不支持嵌套类型化，写前一层，完整结构见注释）
# Array[Array /* [group_type, x, y, tile_id] */]
var _pending: Array[Array] = []
var _p3d_offset := SysCfg.P3D_OFFSET


func _init(layer_id: int, parent: Node2D) -> void:
    _layer_id = layer_id
    _parent = parent
    _create_sub_layers()


# 创建六个子层（对应 Enums.LayerType 六种）
func _create_sub_layers() -> void:
    for t in Enums.LayerType.COUNT:
        var sub_id := sub_layer_id(_layer_id, t)
        if is_p3d_type(t):
            # P3D 层：空 CanvasLayer，精灵稍后添加
            var canvas := CanvasLayer.new()
            canvas.name = "P3D " + Enums.StrLayerType[t]
            canvas.layer = sub_id
            _parent.add_child(canvas)
            _p3d_canvases[sub_id] = canvas
        else:
            # tile 层：TileMapLayer + CanvasLayer
            var map := TileMapLayer.new()
            map.name = "Tile " + Enums.StrLayerType[t]
            map.tile_set = TileSetPreset.tileset
            var canvas := CanvasLayer.new()
            canvas.name = "Canvas " + Enums.StrLayerType[t]
            canvas.layer = sub_id
            canvas.add_child(map)
            _parent.add_child(canvas)
            _tile_maps[sub_id] = map


# 记录 tile 到 map_content（tile 与 P3D 配套共用，key 用普通类型 BACK/MIDDLE/FRONT）
# layer_type 传普通组类型（BACK/MIDDLE/FRONT），同时放置配套的 tile 和 P3D
# 循环1：只记录，不放置
func place(layer_type: int, x: int, y: int, tile_id: int) -> void:
    var g := group_key(layer_type)
    if not _map_content.has(g):
        _map_content[g] = {}
    var blocks: Dictionary = _map_content[g]
    var block_coord := Vector2i(floori(float(x) / SysCfg.BLOCK_SIZE), floori(float(y) / SysCfg.BLOCK_SIZE))
    if not blocks.has(block_coord):
        blocks[block_coord] = _create_block()
    var matrix: Array = blocks[block_coord]
    var lx := x - block_coord.x * SysCfg.BLOCK_SIZE
    var ly := y - block_coord.y * SysCfg.BLOCK_SIZE
    matrix[ly * SysCfg.BLOCK_SIZE + lx] = tile_id
    _pending.append([g, x, y, tile_id])


# 循环2：根据 map_content 放置所有 tile 和 P3D（每个位置同时放 tile 到普通层 + P3D 到配套 P3D 层）
func build() -> void:
    # 先放置所有 tile（到普通层 layer_type）
    for entry in _pending:
        _place_tile(entry[0], entry[1], entry[2], entry[3])
    # 再放置所有 P3D（到配套 P3D 层 layer_type-1，此时所有 tile 已记录可查擦除矩阵）
    for entry in _pending:
        _place_p3d(entry[0] - 1, entry[1], entry[2], entry[3])


# 查询 (x,y) 在组 g 内三个邻居(上/右上/右)的 tile id，供擦除矩阵使用
func get_neighbor(g: int, x: int, y: int) -> Array:
    return [
        _get_cell_id(g, x, y - 1),       # 上
        _get_cell_id(g, x + 1, y - 1),   # 右上
        _get_cell_id(g, x + 1, y),       # 右
    ]


func _get_cell_id(g: int, x: int, y: int) -> int:
    var blocks: Dictionary = _map_content.get(g)
    if blocks == null:
        return -1
    var block_coord := Vector2i(floori(float(x) / SysCfg.BLOCK_SIZE), floori(float(y) / SysCfg.BLOCK_SIZE))
    var matrix = blocks.get(block_coord)
    if matrix == null:
        return -1
    var lx := x - block_coord.x * SysCfg.BLOCK_SIZE
    var ly := y - block_coord.y * SysCfg.BLOCK_SIZE
    if lx < 0 or lx >= SysCfg.BLOCK_SIZE or ly < 0 or ly >= SysCfg.BLOCK_SIZE:
        return -1
    return matrix[ly * SysCfg.BLOCK_SIZE + lx]


func _place_tile(layer_type: int, x: int, y: int, tile_id: int) -> void:
    var info: Array = TileSetPreset.get_tile_id_info(tile_id)
    var source_id: int = TileSetPreset.get_source_id(info[0])
    _tile_maps[sub_layer_id(_layer_id, layer_type)].set_cell(Vector2i(x, y), source_id, info[1])


func _place_p3d(layer_type: int, x: int, y: int, tile_id: int) -> void:
    var info: Array = TileSetPreset.get_tile_id_info(tile_id)
    var source_name: String = info[0]
    var atlas_coords: Vector2i = info[1]
    var sprite := TileSetPreset.create_p3d_sprite(source_name, atlas_coords)
    sprite.position = Vector2(x * 32, y * 32) - _p3d_offset
    sprite.name = str(x) + "," + str(y)
    sprite.z_index = x - y
    # P3D 遮挡擦除：查询同组邻居，生成擦除掩码纹理传给 shader
    var g := group_key(layer_type)
    var mat := ShaderMaterial.new()
    mat.shader = TMapSys.erase_shader
    mat.set_shader_parameter("erase_mask",
        TilemapP3DEraseMask.get_erase_mask(
            func(px: int, py: int) -> Array: return get_neighbor(g, px, py),
            x, y, tile_id, _p3d_offset))
    mat.set_shader_parameter("mode", 1)  # 0=置红可视化，1=删除挖空
    var atlas := sprite.texture as AtlasTexture
    if atlas != null and atlas.atlas != null:
        var atlas_size := atlas.atlas.get_size()
        mat.set_shader_parameter("region_offset", atlas.region.position / atlas_size)
        mat.set_shader_parameter("region_scale", atlas.region.size / atlas_size)
    sprite.material = mat
    _p3d_canvases[sub_layer_id(_layer_id, layer_type)].add_child(sprite)


func _create_block() -> Array:
    var matrix: Array = []
    matrix.resize(SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE)
    for i in SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE:
        matrix[i] = -1
    return matrix
