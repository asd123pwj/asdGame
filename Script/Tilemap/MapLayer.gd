class_name MapLayer
extends RefCounted

# 子层 id = layer_id * COUNT + layer_type
static func sub_layer_id(layer_id: int, layer_type: int) -> int:
    return layer_id * Enums.LayerType.COUNT + layer_type


# 判断 layer_type 是否为 P3D 类型（仅 MIDDLE_P3D 有 P3D 素材）
static func is_p3d_type(layer_type: int) -> bool:
    return layer_type == Enums.LayerType.MIDDLE_P3D


# 映射 layer_type 到组 key。MIDDLE_P3D 与 MIDDLE 配套共用一组；PLANT 独立一组。
static func group_key(layer_type: int) -> int:
    match layer_type:
        Enums.LayerType.MIDDLE_P3D, Enums.LayerType.MIDDLE:
            return 0
        Enums.LayerType.PLANT:
            return 1
    return layer_type


# 组 key -> 该组放置普通 tile 的 layer_type
static func group_to_tile_layer(g: int) -> int:
    match g:
        0:
            return Enums.LayerType.MIDDLE
        1:
            return Enums.LayerType.PLANT
    return g


# 组 key 是否有 P3D 素材（仅 Middle 组有）
static func group_has_p3d(g: int) -> bool:
    return g == 0


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
var _pending: Dictionary[Vector3i, Dictionary] = {}
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
            map.tile_set = TileSpritePreset.tileset
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
            map.tile_set = TileSpritePreset.tileset
            var canvas := CanvasLayer.new()
            canvas.name = "Canvas " + Enums.StrLayerType[t]
            canvas.layer = sub_id
            canvas.add_child(map)
            _parent.add_child(canvas)
            _tile_maps[sub_id] = map


# 记录单格 tile 到 map_content 与 pending（循环1：只记录，不放置）
func place(layer_type: int, x: int, y: int, tile_id: int, is_fix: bool = false) -> void:
    var g := group_key(layer_type)
    _set_content_cell(g, x, y, tile_id)
    _pending[Vector3i(g, x, y)] = {"tile_id": tile_id, "isFix": is_fix}


# 记录一组多格 tile：锚点 (x,y) 记录到 pending（build 时展开整组），整组所有子tile 位置都写入 map_content。
func place_group(layer_type: int, x: int, y: int, tile_id: int, is_fix: bool = false) -> void:
    var g := group_key(layer_type)
    var parts := TileSetPreset.get_tile_parts_by_id(tile_id)
    for part in parts:
        _set_content_cell(g, x + part.dx, y + part.dy, tile_id)
    _pending[Vector3i(g, x, y)] = {"tile_id": tile_id, "isFix": is_fix}
    if false:
        print("[MapLayer] place_group layer=", layer_type, " g=", g, " anchor=(", x, ",", y, ") id=", tile_id)


# 把 tile_id 写入 group 对应区块 matrix（自动创建缺失的组/区块）
func _set_content_cell(g: int, x: int, y: int, tile_id: int) -> void:
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


# 循环2：根据 map_content 放置所有 tile 和 P3D。
# tile 放到对应普通层；仅 Middle 组放置 P3D 到 MIDDLE_P3D 层。
func build() -> void:
    # 先基于邻居进行 tile 匹配，更新 map_content（可能改变各位置 tile）
    _apply_tile_match()
    # 放置所有 tile（到普通层）
    for pos: Vector3i in _pending:
        var g: int = pos.x
        _place_tile(g, pos.y, pos.z, _get_cell_id(g, pos.y, pos.z))
    # 仅 Middle 组放置 P3D（此时所有 tile 已记录可查擦除矩阵）
    for pos: Vector3i in _pending:
        var g: int = pos.x
        if group_has_p3d(g):
            _place_p3d(g, pos.y, pos.z, _get_cell_id(g, pos.y, pos.z))


# 基于邻居情况对已放置的 tile 进行匹配，更新 map_content（可能改变各位置 tile）
func _apply_tile_match() -> void:
    for g in _pending_group_keys():
        var rule := _get_rule_for_group(g)
        if rule == null:
            continue
        # 1. 收集所有需要匹配的位置（_pending 位置 + reference_pos 邻居）
        var match_queue := _collect_match_queue(g, rule)
        # 2. 遍历匹配，若 tile_name 变化则更新 map_content（isFix 固定位置跳过）
        for pos in match_queue:
            # 固定位置（place 时指定了 tile_name）不参与匹配
            if _pending.has(Vector3i(g, pos.x, pos.y)):
                var pend: Dictionary = _pending[Vector3i(g, pos.x, pos.y)]
                if pend.isFix:
                    continue
            var tile_id := _get_cell_id(g, pos.x, pos.y)
            if tile_id < 0:
                continue
            var info: Array = TileSetPreset.get_tile_id_info(tile_id)
            var neighbor_map := _build_neighbor_map(g, rule, pos.x, pos.y)
            var new_name := rule.match(neighbor_map)
            if new_name.is_empty():
                continue
            if TileSetPreset.has_tile_name(info[0], new_name):
                # 匹配生成的新 tile 也随机选变种（跨素材随机）
                var vcount := TileSetPreset.get_tile_variant_count(info[0], new_name)
                var new_id := TileSetPreset.get_or_register_tile_id(
                    info[0], new_name, randi() % maxi(1, vcount))
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
        var pend: Dictionary = _pending[pos]
        var info: Array = TileSetPreset.get_tile_id_info(pend.tile_id)
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


# 构建邻居规则值映射：检查 reference_pos 各偏移在可检查层中是否有 tile，并按规则异同返回。
# 值：1=空，3=非空但规则不同，4=非空且规则相同。
# 可检查的层由 Enums.layer_can_match 决定；若未配置则默认只检查自身层。
func _build_neighbor_map(g: int, rule: TileMatchRulePreset, x: int, y: int) -> Dictionary:
    var neighbor_map: Dictionary = {}
    var layer_type := group_to_tile_layer(g)
    var check_layers: Array = Enums.layer_can_match.get(layer_type, [layer_type])
    # 需要检查的 group 集合（去重）
    var check_groups: Array = []
    for lt in check_layers:
        var gg := group_key(lt)
        if not check_groups.has(gg):
            check_groups.append(gg)
    for offset in rule.reference_pos:
        var nx := x + offset.x
        var ny := y + offset.y
        var value: int = TileMatchRulePreset.RuleType.IS_NULL  # 默认空
        for gg in check_groups:
            var tid := _get_cell_id(gg, nx, ny)
            if tid >= 0:
                # 非空：判断邻居规则是否与当前相同
                var info: Array = TileSetPreset.get_tile_id_info(tid)
                var neighbor_rule: String = TileSetPreset.get_(info[0]).tile_match_rule_name
                value = TileMatchRulePreset.RuleType.SAME_RULE if neighbor_rule == rule.name else TileMatchRulePreset.RuleType.DIFF_RULE
                break
        neighbor_map[offset] = value
    return neighbor_map


func _set_cell_id(g: int, x: int, y: int, tile_id: int) -> void:
    if not _map_content.has(g):
        return
    var blocks: Dictionary = _map_content[g]
    var block_coord := Vector2i(floori(float(x) / SysCfg.BLOCK_SIZE), floori(float(y) / SysCfg.BLOCK_SIZE))
    if not blocks.has(block_coord):
        return
    var matrix: Array = blocks[block_coord]
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


# 查询某 layer_type 在 (x,y) 是否已有 tile（供放置规则查询空间/兼容）
func has_tile(layer_type: int, x: int, y: int) -> bool:
    return _get_cell_id(group_key(layer_type), x, y) >= 0


# 查询某 layer_type 在 (x,y) 的 tile 是否具有 tag（供放置规则查询九宫格）
func tile_has_tag(layer_type: int, x: int, y: int, tag: String) -> bool:
    var tid := _get_cell_id(group_key(layer_type), x, y)
    if tid < 0:
        return false
    var info: Array = TileSetPreset.get_tile_id_info(tid)
    return TileSetPreset.has_tag(info[0], info[1], tag)


func _get_cell_id(g: int, x: int, y: int) -> int:
    if not _map_content.has(g):
        return -1
    var blocks: Dictionary = _map_content[g]
    var block_coord := Vector2i(floori(float(x) / SysCfg.BLOCK_SIZE), floori(float(y) / SysCfg.BLOCK_SIZE))
    var matrix = blocks.get(block_coord)
    if matrix == null:
        return -1
    var lx := x - block_coord.x * SysCfg.BLOCK_SIZE
    var ly := y - block_coord.y * SysCfg.BLOCK_SIZE
    if lx < 0 or lx >= SysCfg.BLOCK_SIZE or ly < 0 or ly >= SysCfg.BLOCK_SIZE:
        return -1
    return matrix[ly * SysCfg.BLOCK_SIZE + lx]


func _place_tile(g: int, x: int, y: int, tile_id: int) -> void:
    if tile_id < 0:
        return
    var parts := TileSetPreset.get_tile_parts_by_id(tile_id)
    if parts.is_empty():
        return
    var layer_type := group_to_tile_layer(g)
    var map := _tile_maps[sub_layer_id(_layer_id, layer_type)]
    for part in parts:
        # Godot y 轴向下为正，逻辑坐标 y 向上为正，放置时对 y 取反
        map.set_cell(Vector2i(x + part.dx, -(y + part.dy)), part.source_id, part.coords)


func _place_p3d(g: int, x: int, y: int, tile_id: int) -> void:
    if tile_id < 0:
        return
    var info: Array = TileSetPreset.get_tile_id_info(tile_id)
    # 解析该 tile 变种对应的素材与坐标（擦除矩阵基于素材）
    var vinfo: Array = TileSetPreset.get_tile_variant_info(info[0], info[1], info[2])
    var sprite_name: String = vinfo[0]
    var atlas_coords: Vector2i = vinfo[1]
    # P3D 遮挡擦除：查询同组邻居，生成掩码，注册/获取掩码后的 P3D 变体 tile，用 tilemap 放置
    var mask: BitMap = TileP3DEraseMask.get_or_build_mask(
        func(px: int, py: int) -> Array: return get_neighbor(g, px, py), x, y, _p3d_offset)
    var masked: Dictionary = TileSetPreset.get_or_register_masked_p3d(
        sprite_name, atlas_coords, mask)
    var p3d_map: TileMapLayer = _p3d_maps[sub_layer_id(_layer_id, Enums.LayerType.MIDDLE_P3D)]
    p3d_map.set_cell(Vector2i(x, -y), masked.source_id, masked.atlas_coords)


func _create_block() -> Array:
    var matrix: Array = []
    matrix.resize(SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE)
    for i in SysCfg.BLOCK_SIZE * SysCfg.BLOCK_SIZE:
        matrix[i] = -1
    return matrix
