class_name TilemapP3DEraseMask
extends RefCounted

# 擦除掩码缓存：key = 当前+三邻居的擦除 ID 组合，value = 擦除掩码纹理
static var _erase_cache: Dictionary = {}

# ---- 内容矩阵缓存 ----
# key("T|source|coords" / "P|source|coords") -> BitMap(48x48)
static var _content_cache: Dictionary = {}

# ---- 擦除矩阵注册表 ----
# 形状哈希 -> 擦除 ID（相同形状共享 ID）
static var _erase_id_by_hash: Dictionary = {}
# 擦除 ID -> 内容矩阵(BitMap 48x48)
static var _erase_matrix_by_id: Dictionary = {}
# "source|atlas_coords" -> 擦除 ID（擦除矩阵 = tile∪P3D 完整轮廓）
static var _erase_id_map: Dictionary = {}
static var _next_erase_id: int = 0


# 获取指定 source 的内容矩阵（48x48 alpha 位图，有内容处为 true）
# 基于 source 图集指定 atlas_coords 区域计算，按 "T|source|coords" 缓存复用
static func get_content_matrix(source_name: String, atlas_coords := Vector2i(0, 2)) -> BitMap:
    var key := "T|" + source_name + "|" + str(atlas_coords)
    if _content_cache.has(key):
        return _content_cache[key]
    var bit_map := TileSetPreset.build_alpha_bitmap(
        TileSetPreset.get_region_image(source_name, atlas_coords, false))
    _content_cache[key] = bit_map
    return bit_map


# 获取指定 source 的 P3D 内容矩阵（48x48 alpha 位图）
# 基于 P3D 图集(source_P3D)指定 atlas_coords 区域计算，按 "P|source|coords" 缓存
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
    # 计算 tile∪P3D 并集矩阵，按形状哈希分配 ID
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


# 获取当前 tile 及其三个遮挡邻居(上/右上/右)的擦除掩码纹理(48x48)
# get_neighbor: Callable，接收 (x, y)，返回三个邻居 [上, 右上, 右] 的 int tile id（无 tile 为 -1）
# tile_id: 当前 tile 的注册 id（tile 与 P3D 共用）
# p3d_offset: P3D 精灵相对格子的偏移，用于计算邻居 region 位置
static func get_erase_mask(get_neighbor: Callable, x: int, y: int,
        tile_id: int, p3d_offset: Vector2) -> ImageTexture:
    var neighbors: Array = get_neighbor.call(x, y)
    var current_info: Array = TileSetPreset.get_tile_id_info(tile_id)
    var key := str(get_erase_id(current_info[0], current_info[1]))
    for id in neighbors:
        if id < 0:
            key += "|_"
        else:
            var info: Array = TileSetPreset.get_tile_id_info(id)
            key += "|" + str(get_erase_id(info[0], info[1]))
    if _erase_cache.has(key):
        return _erase_cache[key]
    var img := _build_erase_mask(x, y, neighbors, p3d_offset)
    # 可视化：需要检查掩码时改为 if true，会把擦除掩码保存为 PNG（文件名用缓存名）
    if true:
        var red_count := 0
        for py in 48:
            for px in 48:
                var c := img.get_pixel(px, py)
                if c.r > 0.5:
                    red_count += 1
        print("[debug] 掩码 key=", key, " 红色像素=", red_count, " 尺寸=", img.get_size())
        var dir := "res://Debug"
        DirAccess.make_dir_recursive_absolute(dir)
        img.save_png(dir + "/" + _safe_filename(key) + ".png")
    var tex := ImageTexture.create_from_image(img)
    _erase_cache[key] = tex
    return tex


# 把三个邻居内容矩阵合并成 48x48 的擦除掩码，偏移到当前 P3D 精灵局部坐标系
static func _build_erase_mask(x: int, y: int, neighbors: Array, p3d_offset: Vector2) -> Image:
    var img := Image.create(48, 48, false, Image.FORMAT_RGB8)
    img.fill(Color(0, 0, 0))
    var origin := Vector2(x * 32, y * 32) - p3d_offset  # P3D 精灵左上角世界坐标
    var neighbor_cells: Array[Vector2i] = [
        Vector2i(x, y - 1),       # 上
        Vector2i(x + 1, y - 1),   # 右上
        Vector2i(x + 1, y),       # 右
    ]
    for i in 3:
        var id: int = neighbors[i]
        if id < 0:
            continue
        var info: Array = TileSetPreset.get_tile_id_info(id)
        var nsrc: String = info[0]
        var ncoords: Vector2i = info[1]
        # 邻居经 texture_origin 左下角对齐后，region 左上角与 P3D 精灵一致：= (格子*32) - p3d_offset
        var nc: Vector2i = neighbor_cells[i]
        var nbase := Vector2(nc.x * 32, nc.y * 32) - p3d_offset
        # 邻居擦除矩阵 = tile∪P3D 完整轮廓，作为整体绘制
        _blit_matrix_to_mask(get_erase_matrix_by_id(get_erase_id(nsrc, ncoords)), nbase, origin, img)
    return img


# 把一个内容矩阵(48x48)按 nbase 偏移绘制到擦除掩码 img（P3D 局部坐标系 origin 基准）
static func _blit_matrix_to_mask(matrix: BitMap, nbase: Vector2, origin: Vector2, img: Image) -> void:
    for my in 48:
        for mx in 48:
            if not matrix.get_bit(mx, my):
                continue
            var lx := int(nbase.x + mx - origin.x)
            var ly := int(nbase.y + my - origin.y)
            if lx >= 0 and lx < 48 and ly >= 0 and ly < 48:
                img.set_pixel(lx, ly, Color(1, 0, 0))


# 把缓存名转为安全文件名（替换路径中不合法的字符）
static func _safe_filename(name: String) -> String:
    return name.replace("/", "_").replace("\\", "_").replace(":", "_").replace("*", "_") \
        .replace("?", "_").replace("\"", "_").replace("<", "_").replace(">", "_").replace("|", "_")
