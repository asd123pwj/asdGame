class_name TileP3DEraseMask
extends RefCounted

# P3D 遮挡擦除：把三个邻居的内容矩阵（来自 TileSpritePreset 的擦除矩阵）合并成掩码，
# 挖空当前 P3D 被邻居遮挡的部分。擦除矩阵（内容矩阵/erase id）已由 TileSpritePreset 提供。

# ---- 掩码缓存 ----
# 邻居 hash 组合 key -> 掩码 BitMap(48x48, true=被邻居遮挡)
static var _mask_cache: Dictionary = {}


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
        # 解析邻居 tile 对应的素材与坐标，取该素材的擦除矩阵
        var vinfo: Array = TileSetPreset.get_tile_variant_info(info[0], info[1], info[2])
        var nsrc: String = vinfo[0]
        var ncoords: Vector2i = vinfo[1]
        var nc: Vector2i = neighbor_cells[i]
        var nbase := Vector2(nc.x * 32, nc.y * 32) - p3d_offset
        var erase_matrix: BitMap = TileSpritePreset.get_erase_matrix_by_id(
            TileSpritePreset.get_erase_id(nsrc, ncoords))
        _blit_matrix_to_mask(erase_matrix, nbase, origin, mask)
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
static func build_masked_p3d_image(sprite_name: String, atlas_coords: Vector2i,
        mask: BitMap) -> Image:
    var p3d: Image = TileSpritePreset.get_region_image(sprite_name, atlas_coords, true)
    for y in 48:
        for x in 48:
            if mask.get_bit(x, y):
                p3d.set_pixel(x, y, Color(0, 0, 0, 0))
    return p3d
