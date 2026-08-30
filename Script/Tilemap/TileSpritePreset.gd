class_name TileSpritePreset
extends PresetRegister

# 单个图片素材：只负责 source 加载、region 读取、碰撞体、hash、图集尺寸等素材相关计算。
# 不关心 tile 名称（tile_name → 行列 的解析由 TileSetPreset 用 match_rule 完成）。
# P3D 素材按同目录下 "xxx_P3D" 后缀文件是否存在来决定是否加载。

var name: String
var region_size: int
var path: String
var path_P3D: String
var has_p3d: bool = false

var source: TileSetAtlasSource
var source_id: int = -1
var source_P3D: TileSetAtlasSource
var source_id_P3D: int = -1

static var _we: Dictionary[String, TileSpritePreset] = {}
# 所有素材共享同一个 TileSet，各素材的 source 都加入其中
static var tileset: TileSet = _create_tileset()

# ---- 形状哈希缓存（碰撞体复用）----
static var _shape_cache: Dictionary = {}
# ---- 图集图像缓存（判空/region 复用，避免重复 get_image）----
static var _atlas_img_cache: Dictionary = {}
# ---- 命名解析：sprite_name -> "行,列" -> atlas_coords ----
static var _tile_name_coords: Dictionary = {}
# ---- 擦除矩阵注册表（擦除矩阵 = tile∪P3D 完整轮廓）----
static var _content_cache: Dictionary = {}
static var _erase_id_by_hash: Dictionary = {}
static var _erase_matrix_by_id: Dictionary = {}
static var _erase_id_map: Dictionary = {}
static var _next_erase_id: int = 0


func _init(name: String, region_size: int, path: String) -> void:
    _we[name] = self
    self.name = name
    self.region_size = region_size
    self.path = path
    # P3D：同目录下是否存在 "_P3D" 后缀文件，有则加载，无则忽略
    var p3d_path := path.get_basename() + "_P3D." + path.get_extension()
    if ResourceLoader.exists(p3d_path):
        path_P3D = p3d_path
        has_p3d = true

    source = _create_source(path, region_size)
    source_id = tileset.add_source(source)
    _create_tiles(source, true)

    if has_p3d:
        source_P3D = _create_source(path_P3D, region_size)
        source_id_P3D = tileset.add_source(source_P3D)
        _create_tiles(source_P3D, false)  # P3D source：只显示图像，无碰撞体

    _build_tile_name_map(name)


# 按行列位置命名素材内每个格（"x,y" → atlas_coords），供行列定位与 Debug
static func _build_tile_name_map(sprite_name: String) -> void:
    var map: Dictionary = {}
    var rows := get_row_count(sprite_name)
    var cols := get_column_count(sprite_name)
    for row in rows:
        for col in cols:
            map[str(col) + "," + str(row)] = Vector2i(col, row)
    _tile_name_coords[sprite_name] = map


# 从 atlas_coords 反查素材内行列名称
# static func tile_name_from_coords(sprite_name: String, atlas_coords: Vector2i) -> String:
#     return str(atlas_coords.x) + "," + str(atlas_coords.y)


static func get_(name: String) -> TileSpritePreset:
    return _we[name]


static func get_source_id(name: String) -> int:
    return _we[name].source_id


static func get_source_id_P3D(name: String) -> int:
    return _we[name].source_id_P3D


static func has_p3d_source(name: String) -> bool:
    return _we[name].has_p3d


# 素材图集列数（48x48 网格）
static func get_column_count(name: String) -> int:
    var tex := _we[name].source.texture
    if tex == null:
        return 1
    return _count(tex.get_image().get_size().x, SysCfg.TILE_MARGINS.x, SysCfg.TILE_SEPARATION.x)


# 素材图集行数（48x48 网格）
static func get_row_count(name: String) -> int:
    var tex := _we[name].source.texture
    if tex == null:
        return 1
    return _count(tex.get_image().get_size().y, SysCfg.TILE_MARGINS.y, SysCfg.TILE_SEPARATION.y)


# 获取素材整张图集图像（缓存，避免重复 get_image）。is_p3d 为 true 取 P3D 图集。
static func get_atlas_image(name: String, is_p3d: bool) -> Image:
    var key := name + ("_P3D" if is_p3d else "")
    if _atlas_img_cache.has(key):
        return _atlas_img_cache[key]
    var preset := _we[name]
    var src := preset.source_P3D if is_p3d else preset.source
    if src == null:
        _atlas_img_cache[key] = null
        return null
    var img := src.texture.get_image()
    _atlas_img_cache[key] = img
    return img


# 获取素材指定 region 图像（48x48）。is_p3d 为 true 取 P3D 图集；无 P3D 返回全透明。
static func get_region_image(name: String, atlas_coords: Vector2i, is_p3d: bool) -> Image:
    var img := get_atlas_image(name, is_p3d)
    if img == null:
        var empty := Image.create(SysCfg.REGION_SIZE.x, SysCfg.REGION_SIZE.y, false, Image.FORMAT_RGBA8)
        empty.fill(Color(0, 0, 0, 0))
        return empty
    var region := Rect2i(SysCfg.TILE_MARGINS + atlas_coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    return img.get_region(region)


# 判断某 atlas 格是否为空（alpha 全空）
static func is_cell_empty(name: String, atlas_coords: Vector2i, is_p3d: bool) -> bool:
    var img := get_atlas_image(name, is_p3d)
    if img == null:
        return true
    var region := Rect2i(SysCfg.TILE_MARGINS + atlas_coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    return img.get_region(region).get_used_rect().size == Vector2i.ZERO


# 获取素材内某格 tile 的形状哈希（alpha 哈希，相同形状共享）
static func get_tile_shape_hash(name: String, atlas_coords: Vector2i) -> String:
    return _hash_alpha(get_region_image(name, atlas_coords, false))


# 根据瓦片图像生成 alpha>0 的位图（48x48）
static func build_alpha_bitmap(image: Image) -> BitMap:
    var bit_map := BitMap.new()
    bit_map.create(Vector2i(SysCfg.REGION_SIZE.x, SysCfg.REGION_SIZE.y))
    var alpha_img: Image = image.duplicate()
    alpha_img.convert(Image.FORMAT_LA8)
    var data := alpha_img.get_data()
    @warning_ignore("integer_division")
    for idx in data.size() / 2:
        if data[idx * 2 + 1] > 0:
            bit_map.set_bit(idx % SysCfg.REGION_SIZE.x, floori(float(idx) / SysCfg.REGION_SIZE.x), true)
    return bit_map


# 获取素材指定格的内容矩阵（48x48 alpha 位图，有内容处为 true）
static func get_content_matrix(sprite_name: String, atlas_coords: Vector2i) -> BitMap:
    var key := "T|" + sprite_name + "|" + str(atlas_coords)
    if _content_cache.has(key):
        return _content_cache[key]
    var bit_map := build_alpha_bitmap(get_region_image(sprite_name, atlas_coords, false))
    _content_cache[key] = bit_map
    return bit_map


# 获取素材指定格的 P3D 内容矩阵（48x48 alpha 位图）
static func get_p3d_content_matrix(sprite_name: String, atlas_coords: Vector2i) -> BitMap:
    var key := "P|" + sprite_name + "|" + str(atlas_coords)
    if _content_cache.has(key):
        return _content_cache[key]
    var bit_map := build_alpha_bitmap(get_region_image(sprite_name, atlas_coords, true))
    _content_cache[key] = bit_map
    return bit_map


# 获取素材指定格的擦除矩阵 ID。擦除矩阵 = tile∪P3D 完整轮廓（并集）。相同形状共享 ID。
static func get_erase_id(sprite_name: String, atlas_coords: Vector2i) -> int:
    var key := sprite_name + "|" + str(atlas_coords)
    if _erase_id_map.has(key):
        return _erase_id_map[key]
    var bit_map := _union_bitmap(
        get_content_matrix(sprite_name, atlas_coords),
        get_p3d_content_matrix(sprite_name, atlas_coords))
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


static func _create_tileset() -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = SysCfg.GRID_SIZE
    ts.add_physics_layer()
    ts.set_physics_layer_collision_layer(0, 1)
    ts.set_physics_layer_collision_mask(0, 1)
    return ts


# 创建 source（仅配置，不含瓦片）；region_size 小于 48 时先预处理成 48x48
static func _create_source(path: String, region_size: int) -> TileSetAtlasSource:
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("TileSpritePreset: 无法加载贴图: ", path)
        return TileSetAtlasSource.new()
    var img: Image = texture.get_image()
    if region_size != SysCfg.REGION_SIZE.x:
        img = _to_48_atlas(img, region_size)
        if false:
            _save_debug_png(img, path.get_file().get_basename() + "_48.png")
    var source := TileSetAtlasSource.new()
    source.texture = ImageTexture.create_from_image(img)
    source.texture_region_size = SysCfg.REGION_SIZE
    source.margins = SysCfg.TILE_MARGINS
    source.separation = SysCfg.TILE_SEPARATION
    return source


static func _to_48_atlas(image: Image, region_size: int) -> Image:
    var rsize := region_size
    @warning_ignore("integer_division")
    var cols := image.get_width() / rsize
    @warning_ignore("integer_division")
    var rows := image.get_height() / rsize
    var out := Image.create(
        cols * SysCfg.REGION_SIZE.x, rows * SysCfg.REGION_SIZE.y,
        false, image.get_format())
    out.fill(Color(0, 0, 0, 0))
    var dy := SysCfg.REGION_SIZE.y - rsize
    for cy in rows:
        for cx in cols:
            var src_rect := Rect2i(cx * rsize, cy * rsize, rsize, rsize)
            out.blit_rect(image, src_rect,
                Vector2i(cx * SysCfg.REGION_SIZE.x, cy * SysCfg.REGION_SIZE.y + dy))
    return out


static func _count(tex_len: int, margin: int, separation: int) -> int:
    var n := 0
    while margin + n * (SysCfg.REGION_SIZE.x + separation) + SysCfg.REGION_SIZE.x <= tex_len:
        n += 1
    return n


# 遍历创建所有瓦片；with_collision 为 false 时只创建图像，不生成碰撞体
static func _create_tiles(source: TileSetAtlasSource, with_collision: bool = true) -> void:
    var texture: Texture2D = source.texture
    var tex_size: Vector2i = texture.get_image().get_size()
    for y in _count(tex_size.y, SysCfg.TILE_MARGINS.y, SysCfg.TILE_SEPARATION.y):
        for x in _count(tex_size.x, SysCfg.TILE_MARGINS.x, SysCfg.TILE_SEPARATION.x):
            var coords := Vector2i(x, y)
            source.create_tile(coords)
            var tile_data := source.get_tile_data(coords, 0)
            tile_data.texture_origin = Vector2i(-8, 8)
            if with_collision:
                _set_tile_collision(source, texture, coords)


static func _set_tile_collision(source: TileSetAtlasSource, texture: Texture2D, coords: Vector2i) -> void:
    var region := Rect2i(SysCfg.TILE_MARGINS + coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    var image := texture.get_image().get_region(region)
    var entry := _get_or_build_shape(image)
    if entry.is_empty():
        return
    var tile_data: TileData = source.get_tile_data(coords, 0)
    var polygons: Array = entry.poly
    for i in polygons.size():
        tile_data.add_collision_polygon(0)
        tile_data.set_collision_polygon_points(0, i, polygons[i])


static func _get_or_build_shape(image: Image) -> Dictionary:
    var key := _hash_alpha(image)
    if _shape_cache.has(key):
        return _shape_cache[key]
    if image.get_used_rect().size == Vector2i.ZERO:
        _shape_cache[key] = {}
        return {}
    var entry := {
        "poly": _build_polygons(image),
        "rect": _build_bounding_rect(image),
    }
    _shape_cache[key] = entry
    return entry


static func _build_bounding_rect(image: Image) -> Array:
    var rect: Rect2i = image.get_used_rect()
    if rect.size == Vector2i.ZERO:
        return []
    var half := Vector2(SysCfg.REGION_SIZE) / 2.0
    var offset := Vector2(8, -8)
    var top_left := Vector2(rect.position) - half + offset
    var size := Vector2(rect.size)
    return [PackedVector2Array([
        top_left,
        top_left + Vector2(size.x, 0),
        top_left + size,
        top_left + Vector2(0, size.y),
    ])]


static func _build_polygons(image: Image) -> Array:
    var bit_map := build_alpha_bitmap(image)
    var result: Array = []
    var half := Vector2(SysCfg.REGION_SIZE) / 2.0
    var offset := Vector2(8, -8)
    for raw in bit_map.opaque_to_polygons(Rect2(Vector2.ZERO, SysCfg.REGION_SIZE)):
        var points: PackedVector2Array = raw
        if points.size() > 3 and points[0] == points[points.size() - 1]:
            points.remove_at(points.size() - 1)
        if points.size() >= 3:
            for i in points.size():
                points[i] = points[i] - half + offset
            result.append(points)
    return result


static func _hash_alpha(image: Image) -> String:
    image.convert(Image.FORMAT_LA8)
    var data := image.get_data()
    @warning_ignore("integer_division")
    var n: int = data.size() / 2
    var alpha := PackedByteArray()
    alpha.resize(n)
    for i in n:
        alpha[i] = data[i * 2 + 1]
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_MD5)
    ctx.update(alpha)
    return ctx.finish().hex_encode()


static func _save_debug_png(image: Image, file_name: String) -> void:
    var debug_path: String = SysCfg.DEBUG_DIR + file_name
    DirAccess.make_dir_recursive_absolute(SysCfg.DEBUG_DIR)
    if image.save_png(debug_path) != OK:
        push_error("TileSpritePreset: 保存调试图像失败: ", debug_path)
