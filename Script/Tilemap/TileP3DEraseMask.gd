class_name TileP3DEraseMask
extends RefCounted

# ---- 内容矩阵缓存 ----
# key("T|source|coords" / "P|source|coords") -> BitMap(48x48)
static var _content_cache: Dictionary = {}

# ---- 擦除矩阵注册表 ----
# 形状哈希 -> 擦除 ID（相同形状共享 ID）
static var _erase_id_by_hash: Dictionary = {}
# 擦除 ID -> 内容矩阵(BitMap 48x48)（擦除矩阵 = tile∪P3D 完整轮廓）
static var _erase_matrix_by_id: Dictionary = {}
# "source|atlas_coords" -> 擦除 ID
static var _erase_id_map: Dictionary = {}
static var _next_erase_id: int = 0

# ---- 掩码缓存 ----
# 邻居 hash 组合 key -> 掩码 BitMap(48x48, true=被邻居遮挡)
static var _mask_cache: Dictionary = {}


# 获取指定 source 的内容矩阵（48x48 alpha 位图，有内容处为 true）
static func get_content_matrix(source_name: String, atlas_coords := Vector2i(0, 2)) -> BitMap:
    var key := "T|" + source_name + "|" + str(atlas_coords)
    if _content_cache.has(key):
        return _content_cache[key]
    var bit_map := TileSetPreset.build_alpha_bitmap(
        TileSetPreset.get_region_image(source_name, atlas_coords, false))
    _content_cache[key] = bit_map
    return bit_map


# 获取指定 source 的 P3D 内容矩阵（48x48 alpha 位图）
static func get_p3d_content_matrix(source_name: String, atlas_coords: Vector2i) -> BitMap:
    var key := "P|" + source_name + "|" + str(atlas_coords)
    if _content_cache.has(key):
        return _content_cache[key]
    var bit_map := TileSetPreset.build_alpha_bitmap(
        TileSetPreset.get_region_image(source_name, atlas_coords, true))
    _content_cache[key] = bit_map
    return bit_map


# 获取指定 source 的擦除矩阵 ID。擦除矩阵 = tile∪P3D 完整轮廓（并集）。
# 相同形状（相同 alpha 内容）共享同一 ID。
static func get_erase_id(source_name: String, atlas_coords: Vector2i) -> int:
    var key := source_name + "|" + str(atlas_coords)
    if _erase_id_map.has(key):
        return _erase_id_map[key]
    var bit_map := _union_bitmap(
        get_content_matrix(source_name, atlas_coords),
        get_p3d_content_matrix(source_name, atlas_coords))
    var hash_key := _hash_bitmap(bit_map)
    if _erase_id_by_hash.has(hash_key):
        var id: int = _erase_id_by_hash[hash_key]
        _erase_id_map[key] = id
        return id
    var new_id := _next_erase_id
    _next_erase_id += 1
    _erase_id_by_hash[hash_key] = new_id
    _erase_matrix_by_id[new_id] = bit_map
    _erase_id_map[key] = new_id
    return new_id


# 按擦除 ID 获取内容矩阵
static func get_erase_matrix_by_id(id: int) -> BitMap:
    return _erase_matrix_by_id.get(id)


# 两个 48x48 位图取并集
static func _union_bitmap(a: BitMap, b: BitMap) -> BitMap:
    var result := BitMap.new()
    result.create(Vector2i(SysCfg.REGION_SIZE.x, SysCfg.REGION_SIZE.y))
    for y in SysCfg.REGION_SIZE.y:
        for x in SysCfg.REGION_SIZE.x:
            if a.get_bit(x, y) or b.get_bit(x, y):
                result.set_bit(x, y, true)
    return result


# 对内容矩阵(BitMap)做哈希，相同形状共享
static func _hash_bitmap(bit_map: BitMap) -> String:
    var alpha := PackedByteArray()
    alpha.resize(SysCfg.REGION_SIZE.x * SysCfg.REGION_SIZE.y)
    var n := 0
    for y in SysCfg.REGION_SIZE.y:
        for x in SysCfg.REGION_SIZE.x:
            alpha[n] = 1 if bit_map.get_bit(x, y) else 0
            n += 1
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_MD5)
    ctx.update(alpha)
    return ctx.finish().hex_encode()


# 由三个邻居 tile id 组成掩码缓存键（用邻居 tile 的形状哈希，不含当前 tile）
static func get_neighbor_mask_key(neighbors: Array) -> String:
    var key := ""
    for id in neighbors:
        if id < 0:
            key += "|_"
        else:
            key += "|" + TileSetPreset.get_tile_hash(id)
    return key


# 获取/生成掩码 BitMap（true=该位置被邻居遮挡）。掩码只依赖三邻居组合，共享缓存。
# get_neighbor: Callable (x,y) -> [上,右上,右] 的 int tile id
static func get_or_build_mask(get_neighbor: Callable, x: int, y: int, p3d_offset: Vector2) -> BitMap:
    var neighbors: Array = get_neighbor.call(x, y)
    var key := get_neighbor_mask_key(neighbors)
    if _mask_cache.has(key):
        return _mask_cache[key]
    var mask := _build_erase_bitmap(x, y, neighbors, p3d_offset)
    _mask_cache[key] = mask
    return mask


# 把三个邻居内容矩阵合并成 48x48 掩码 BitMap，偏移到当前 P3D 局部坐标系
static func _build_erase_bitmap(x: int, y: int, neighbors: Array, p3d_offset: Vector2) -> BitMap:
    var mask := BitMap.new()
    mask.create(Vector2i(SysCfg.REGION_SIZE.x, SysCfg.REGION_SIZE.y))
    var origin := Vector2(x * 32, y * 32) - p3d_offset  # P3D 左上角世界坐标
    var neighbor_cells: Array[Vector2i] = [
        Vector2i(x, y + 1),       # 上
        Vector2i(x + 1, y + 1),   # 右上
        Vector2i(x + 1, y),       # 右
    ]
    for i in 3:
        var id: int = neighbors[i]
        if id < 0:
            continue
        var info: Array = TileSetPreset.get_tile_id_info(id)
        var nsrc: String = info[0]
        var ncoords := TileSetPreset.get_tile_info_coords(info)
        var nc: Vector2i = neighbor_cells[i]
        var nbase := Vector2(nc.x * 32, nc.y * 32) - p3d_offset
        _blit_matrix_to_mask(get_erase_matrix_by_id(get_erase_id(nsrc, ncoords)), nbase, origin, mask)
    return mask


# 把一个内容矩阵(48x48)按 nbase 偏移绘制到掩码 BitMap（P3D 局部坐标系 origin 基准）
static func _blit_matrix_to_mask(matrix: BitMap, nbase: Vector2, origin: Vector2, mask: BitMap) -> void:
    for my in 48:
        for mx in 48:
            if not matrix.get_bit(mx, my):
                continue
            var lx := int(nbase.x + mx - origin.x)
            var ly := int(origin.y - nbase.y + my)  # 逻辑坐标 y 向上为正
            if lx >= 0 and lx < 48 and ly >= 0 and ly < 48:
                mask.set_bit(lx, ly, true)


# 生成掩码后的 P3D 图像（P3D 原图，被邻居遮挡处挖空 alpha=0）
static func build_masked_p3d_image(source_name: String, atlas_coords: Vector2i,
        mask: BitMap) -> Image:
    var p3d := TileSetPreset.get_region_image(source_name, atlas_coords, true)
    for y in 48:
        for x in 48:
            if mask.get_bit(x, y):
                p3d.set_pixel(x, y, Color(0, 0, 0, 0))
    return p3d
