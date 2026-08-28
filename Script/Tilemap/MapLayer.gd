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
var _p3d_maps: Dictionary[int, TileMapLayer] = {}
# 多区块（Godot 不支持三层嵌套类型化，只写前两层，完整结构见注释）
# Dictionary[int /* 组key: BACK/MIDDLE/FRONT */, Dictionary[Vector2i /* 区块 */, Array /* 16x16 矩阵(int tile id) */]]
var _map_content: Dictionary[int, Dictionary] = {}
# 记录放置位置 -> tile_id（key: Vector3i(g, x, y)），同一位置重复放置直接覆盖
var _pending: Dictionary[Vector3i, int] = {}
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
            # P3D 层：TileMapLayer（用共享 tileset 放置掩码变体）+ CanvasLayer
            var map := TileMapLayer.new()
            map.name = "P3D " + Enums.StrLayerType[t]
            map.tile_set = TileSetPreset.tileset
            var canvas := CanvasLayer.new()
            canvas.name = "Canvas P3D " + Enums.StrLayerType[t]
            canvas.layer = sub_id
            canvas.add_child(map)
            _parent.add_child(canvas)
            _p3d_canvases[sub_id] = canvas
            _p3d_maps[sub_id] = map
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
    _pending[Vector3i(g, x, y)] = tile_id


# 循环2：根据 map_content 放置所有 tile 和 P3D（每个位置同时放 tile 到普通层 + P3D 到配套 P3D 层）
func build() -> void:
    # 先基于邻居进行 tile 匹配，更新 map_content（可能改变各位置 tile）
    _apply_tile_match()
    # 再放置所有 tile（到普通层 layer_type）
    for pos: Vector3i in _pending:
        var g: int = pos.x
        _place_tile(g, pos.y, pos.z, _get_cell_id(g, pos.y, pos.z))
    # 再放置所有 P3D（到配套 P3D 层 layer_type-1，此时所有 tile 已记录可查擦除矩阵）
    for pos: Vector3i in _pending:
        _place_p3d(pos.x - 1, pos.y, pos.z, _get_cell_id(pos.x, pos.y, pos.z))


# 基于邻居情况对已放置的 tile 进行匹配，更新 map_content（可能改变各位置 tile）
func _apply_tile_match() -> void:
    for g in _pending_group_keys():
        var rule := _get_rule_for_group(g)
        if rule == null:
            continue
        # 1. 收集所有需要匹配的位置（_pending 位置 + reference_pos 邻居）
        var match_queue := _collect_match_queue(g, rule)
        # 2. 遍历匹配，若 tile_name 变化则更新 map_content
        for pos in match_queue:
            var tile_id := _get_cell_id(g, pos.x, pos.y)
            if tile_id < 0:
                continue
            var info: Array = TileSetPreset.get_tile_id_info(tile_id)
            var neighbor_map := _build_neighbor_map(g, rule, pos.x, pos.y)
            var new_name := rule.match(neighbor_map)
            if new_name.is_empty():
                continue
            if TileSetPreset.has_tile_name(info[0], new_name):
                var new_id := TileSetPreset.get_or_register_tile_id(info[0], new_name)
                _set_cell_id(g, pos.x, pos.y, new_id)


# 收集所有出现过的 group key
func _pending_group_keys() -> Array:
    var keys: Array = []
    for pos: Vector3i in _pending:
        var g: int = pos.x
        if not keys.has(g):
            keys.append(g)
    return keys


# 获取 group 内 tile 使用的匹配规则（取 group 里第一个有规则的 source）
func _get_rule_for_group(g: int) -> TileMatchRulePreset:
    for pos: Vector3i in _pending:
        if pos.x != g:
            continue
        var info: Array = TileSetPreset.get_tile_id_info(_pending[pos])
        if TileSetPreset.has_match_rule(info[0]):
            return TileMatchRulePreset.get_(TileSetPreset.get_(info[0]).tile_match_rule_name)
    return null


# 收集所有需匹配位置：_pending 位置 + 每个位置在 reference_pos 范围内的邻居
func _collect_match_queue(g: int, rule: TileMatchRulePreset) -> Array:
    var queue: Array = []
    var visited: Dictionary = {}
    for pos: Vector3i in _pending:
        if pos.x != g:
            continue
        var base := Vector2i(pos.y, pos.z)
        _add_match_pos(queue, visited, base)
        for offset in rule.reference_pos:
            _add_match_pos(queue, visited, base + offset)
    return queue


func _add_match_pos(queue: Array, visited: Dictionary, pos: Vector2i) -> void:
    if visited.has(pos):
        return
    visited[pos] = true
    queue.append(pos)


# 构建邻居非空映射：检查 reference_pos 各偏移的格子是否在 map_content 中
func _build_neighbor_map(g: int, rule: TileMatchRulePreset, x: int, y: int) -> Dictionary:
    var neighbor_map: Dictionary = {}
    for offset in rule.reference_pos:
        var nx := x + offset.x
        var ny := y + offset.y
        neighbor_map[offset] = _get_cell_id(g, nx, ny) >= 0
    return neighbor_map


func _set_cell_id(g: int, x: int, y: int, tile_id: int) -> void:
    var blocks: Dictionary = _map_content.get(g)
    if blocks == null:
        return
    var block_coord := Vector2i(floori(float(x) / SysCfg.BLOCK_SIZE), floori(float(y) / SysCfg.BLOCK_SIZE))
    var matrix: Array = blocks.get(block_coord)
    if matrix == null:
        return
    var lx := x - block_coord.x * SysCfg.BLOCK_SIZE
    var ly := y - block_coord.y * SysCfg.BLOCK_SIZE
    if lx >= 0 and lx < SysCfg.BLOCK_SIZE and ly >= 0 and ly < SysCfg.BLOCK_SIZE:
        matrix[ly * SysCfg.BLOCK_SIZE + lx] = tile_id


# 查询 (x,y) 在组 g 内三个邻居(上/右上/右)的 tile id，供擦除矩阵使用
# 逻辑坐标 y 向上为正：y+1 为上
func get_neighbor(g: int, x: int, y: int) -> Array:
    return [
        _get_cell_id(g, x, y + 1),       # 上
        _get_cell_id(g, x + 1, y + 1),   # 右上
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
    var coords := TileSetPreset.get_tile_info_coords(info)
    # Godot y 轴向下为正，逻辑坐标 y 向上为正，放置时对 y 取反
    _tile_maps[sub_layer_id(_layer_id, layer_type)].set_cell(Vector2i(x, -y), source_id, coords)


func _place_p3d(layer_type: int, x: int, y: int, tile_id: int) -> void:
    var info: Array = TileSetPreset.get_tile_id_info(tile_id)
    var source_name: String = info[0]
    var atlas_coords := TileSetPreset.get_tile_info_coords(info)
    # P3D 遮挡擦除：查询同组邻居，注册/获取掩码后的 P3D 变体 tile，用 tilemap 放置
    var g := group_key(layer_type)
    var neighbors: Array = get_neighbor(g, x, y)
    var masked: Dictionary = TileSetPreset.get_or_register_masked_p3d(
        source_name, atlas_coords, neighbors, _p3d_offset)
    var p3d_map: TileMapLayer = _p3d_maps[sub_layer_id(_layer_id, layer_type)]
    p3d_map.set_cell(Vector2i(x, -y), masked.source_id, masked.atlas_coords)


func _create_block() -> Array:
    var matrix: Array = []
    matrix.resize(SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE)
    for i in SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE:
        matrix[i] = -1
    return matrix
