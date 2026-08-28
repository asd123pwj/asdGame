class_name TileSetPreset
extends PresetRegister

var name: String
var tile_match_rule_name: String
var path: String
var path_P3D: String

var source: TileSetAtlasSource
var source_id: int
var source_P3D: TileSetAtlasSource
var source_id_P3D: int

static var _we: Dictionary[String, TileSetPreset] = {}
static var tileset: TileSet = _create_tileset()
# P3D 瓦片定位校正（texture_origin）。初始值反推自"P3D 显示偏移"，运行后可微调。
static var P3D_TILE_ORIGIN := Vector2i(-8, 8)
# P3D 图集缓存："name|atlas_coords" -> AtlasTexture（纯资源可共享）
static var _atlas_cache: Dictionary = {}

# ---- tile id 注册表 ----
# 列表：序号即 tile id，每个元素为 [source_name, tile_name]
static var _tile_id_list: Array = []
# 映射："source_name|tile_name" -> tile id(序号)
static var _tile_id_map: Dictionary = {}
# tile 名称映射：source_name -> tile_name -> atlas_coords（基于 rule.tiles_name）
static var _tile_name_coords: Dictionary = {}

# ---- 形状哈希缓存 ----
# tile_id -> hash（每个 tile 的形状哈希）
static var _tile_hash_cache: Dictionary = {}
# hash -> {seq: 序号, poly: poly碰撞体, rect: 最小外接矩形碰撞体}
static var _shape_cache: Dictionary = {}
static var _shape_seq_counter: int = 0

# ---- P3D 掩码变体缓存 ----
# P3D tile_id -> {neighbor_hash_key -> {source_id, atlas_coords}}（掩码后的 P3D tile）
static var _p3d_mask_variant_cache: Dictionary = {}
# neighbor_hash_key -> 掩码后的 P3D 图像（跨 tile 共享掩码，但图像依赖当前 P3D，故按 tile 缓存）

func _init(name: String, tile_match_rule_name: String, path: String, path_P3D: String) -> void:
    _we[name] = self
    self.name = name
    self.tile_match_rule_name = tile_match_rule_name
    self.path = path
    self.path_P3D = path_P3D

    source = _create_source(path)
    source_id = tileset.add_source(source)
    _create_tiles(source, name, true)  # 正常 source：有碰撞体

    source_P3D = _create_source(path_P3D)
    source_id_P3D = tileset.add_source(source_P3D)
    _create_tiles(source_P3D, name, false)  # P3D source：只显示图像，无碰撞体

    # 若有匹配规则，基于 tiles_name 为各位置 tile 命名
    if tile_match_rule_name != "":
        _build_tile_name_map(name)


static func get_(name: String) -> TileSetPreset:
    return _we[name]


static func get_source_id(name: String) -> int:
    return _we[name].source_id


static func get_source_id_P3D(name: String) -> int:
    return _we[name].source_id_P3D


# 基于匹配规则的 tiles_name 建立 tile_name -> atlas_coords 映射
static func _build_tile_name_map(source_name: String) -> void:
    var rule := TileMatchRulePreset.get_(_we[source_name].tile_match_rule_name)
    if rule == null:
        return
    var map: Dictionary = {}
    var names: Array = rule.tiles_name
    for row in names.size():
        for col in names[row].size():
            var tile_name: String = names[row][col]
            if not tile_name.is_empty():
                # tiles_name[row][col] 对应 atlas_coords(col, row)
                map[tile_name] = Vector2i(col, row)
    _tile_name_coords[source_name] = map


# 按 tile 名称获取 atlas_coords，找不到返回 Vector2i(-1, -1)
static func get_tile_coords_by_name(source_name: String, tile_name: String) -> Vector2i:
    var map: Dictionary = _tile_name_coords.get(source_name)
    if map == null:
        return Vector2i(-1, -1)
    return map.get(tile_name, Vector2i(-1, -1))


# 获取 source 是否配置了匹配规则名
static func has_match_rule(source_name: String) -> bool:
    return _we[source_name].tile_match_rule_name != ""


# 判断 source 是否存在指定 tile 名称
static func has_tile_name(source_name: String, tile_name: String) -> bool:
    var map: Dictionary = _tile_name_coords.get(source_name)
    return map != null and map.has(tile_name)


# 获取 source 的默认 tile 名称（tiles_name 的 (0,0) 位置）
static func get_default_tile_name(source_name: String) -> String:
    var rule: TileMatchRulePreset = TileMatchRulePreset.get_(_we[source_name].tile_match_rule_name)
    if rule == null or rule.tiles_name.is_empty():
        return ""
    var first_row: Array = rule.tiles_name[0]
    if first_row.is_empty():
        return ""
    return first_row[0]


# 获取/注册 (source_name, tile_name) 的 tile id（列表序号）。tile 与 P3D 共用一个 id。
static func get_or_register_tile_id(source_name: String, tile_name: String) -> int:
    var key := source_name + "|" + tile_name
    if _tile_id_map.has(key):
        return _tile_id_map[key]
    var id := _tile_id_list.size()
    _tile_id_list.append([source_name, tile_name])
    _tile_id_map[key] = id
    # 记录该 tile 的形状哈希（tile 与 P3D 共用 id，这里记录的是 tile 图集形状）
    _tile_hash_cache[id] = get_tile_shape_hash(source_name, tile_name)
    return id


# 获取指定 tile（source_name + tile_name）的形状哈希（基于 tile 图集 alpha）
static func get_tile_shape_hash(source_name: String, tile_name: String) -> String:
    var coords := get_tile_coords_by_name(source_name, tile_name)
    if coords == Vector2i(-1, -1):
        return ""
    return _hash_alpha(get_region_image(source_name, coords, false))


# 按 tile id 获取该 tile 的形状哈希（未注册则为空）
static func get_tile_hash(tile_id: int) -> String:
    return _tile_hash_cache.get(tile_id, "")


# 按形状哈希获取形状数据 {seq, poly, rect}；不存在则返回空字典
static func get_shape_data(hash_val: String) -> Dictionary:
    var entry: Variant = _shape_cache.get(hash_val, {})
    return entry if entry is Dictionary else {}


# 获取指定 tile 的形状数据（hash 不存在则先计算并填充 shape_cache）
static func get_tile_shape_data(tile_id: int) -> Dictionary:
    var hash_val := get_tile_hash(tile_id)
    if hash_val.is_empty():
        return {}
    var entry: Variant = _shape_cache.get(hash_val)
    if entry is Dictionary:
        return entry
    # shape 未生成（可能该 tile 尚未生成碰撞体）：手动生成
    var info := get_tile_id_info(tile_id)
    var coords := get_tile_info_coords(info)
    if coords == Vector2i(-1, -1):
        return {}
    return _get_or_build_shape(get_region_image(info[0], coords, false), info[0])


# 按 tile id 获取 [source_name, tile_name]
static func get_tile_id_info(id: int) -> Array:
    return _tile_id_list[id]


# 把 [source_name, tile_name] 转为 atlas_coords（需要 atlas 时用）
static func get_tile_info_coords(info: Array) -> Vector2i:
    return get_tile_coords_by_name(info[0], info[1])


# 获取指定 source 的图集 region 图像（48x48）。
# is_p3d 为 true 取 P3D 图集(source_P3D)，否则取 tile 图集(source)。
static func get_region_image(source_name: String, atlas_coords: Vector2i, is_p3d: bool) -> Image:
    var preset := _we[source_name]
    var src := preset.source_P3D if is_p3d else preset.source
    var region := Rect2i(SysCfg.TILE_MARGINS + atlas_coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    return src.texture.get_image().get_region(region)


# 为指定瓦片创建伪3D精灵（Sprite2D + AtlasTexture）
# 用 Node2D 的 y_sort 控制遮挡，避免 TileMap 排序限制
static func create_p3d_sprite(name: String, atlas_coords: Vector2i) -> Sprite2D:
    var preset := _we[name]
    # AtlasTexture 是纯资源，可缓存共享；Sprite2D 实例需独立创建
    var atlas_key := name + "|" + str(atlas_coords)
    if not _atlas_cache.has(atlas_key):
        var texture: Texture2D = load(preset.path_P3D)
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(SysCfg.TILE_MARGINS + atlas_coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
        _atlas_cache[atlas_key] = atlas
    var sprite := Sprite2D.new()
    sprite.texture = _atlas_cache[atlas_key]
    sprite.centered = false  # 锚点左上角，便于按瓦片网格定位
    return sprite


# 获取/注册掩码后的 P3D tile（独立的 AtlasSource 变体）。
# neighbors: 三个邻居 [上,右上,右] 的 tile id（无 tile 为 -1）。
# 返回 {source_id, atlas_coords}；缓存于 {P3D_tile_id: {neighbor_hash_key: masked_tile_info}}。
static func get_or_register_masked_p3d(source_name: String, atlas_coords: Vector2i,
        neighbors: Array, p3d_offset: Vector2) -> Dictionary:
    var tile_id := get_or_register_tile_id(source_name, tile_name_from_coords(source_name, atlas_coords))
    var neighbor_key := TileP3DEraseMask.get_neighbor_mask_key(neighbors)
    if _p3d_mask_variant_cache.has(tile_id):
        var variants: Dictionary = _p3d_mask_variant_cache[tile_id]
        if variants.has(neighbor_key):
            return variants[neighbor_key]

    # 生成掩码 BitMap（只依赖三邻居组合，共享缓存）
    var mask := TileP3DEraseMask.get_or_build_mask(
        func(_px: int, _py: int) -> Array: return neighbors,
        Vector2i.ZERO.x, Vector2i.ZERO.y, p3d_offset)
    # 掩码后的 P3D 图像（挖空被邻居遮挡处）
    var masked_img := TileP3DEraseMask.build_masked_p3d_image(source_name, atlas_coords, mask)

    # 生成独立 AtlasSource（掩码后的 P3D tile，无碰撞）
    var src := TileSetAtlasSource.new()
    src.texture = ImageTexture.create_from_image(masked_img)
    src.texture_region_size = SysCfg.REGION_SIZE
    src.margins = SysCfg.TILE_MARGINS
    src.separation = SysCfg.TILE_SEPARATION
    src.create_tile(Vector2i(0, 0))
    var source_id: int = tileset.add_source(src)
    # P3D 定位校正：用 texture_origin 调整瓦片绘制位置。
    # 初始值基于"P3D 显示偏移"反推，可运行后微调。
    var td: TileData = src.get_tile_data(Vector2i(0, 0), 0)
    @warning_ignore("unsafe_property_access")
    td.texture_origin = P3D_TILE_ORIGIN

    var info := {"source_id": source_id, "atlas_coords": Vector2i(0, 0)}
    if not _p3d_mask_variant_cache.has(tile_id):
        _p3d_mask_variant_cache[tile_id] = {}
    _p3d_mask_variant_cache[tile_id][neighbor_key] = info
    return info


# 从 atlas_coords 反查 tile_name（用于掩码变体注册时的 tile_id）
static func tile_name_from_coords(source_name: String, atlas_coords: Vector2i) -> String:
    for tile_name in _tile_name_coords.get(source_name, {}):
        if _tile_name_coords[source_name][tile_name] == atlas_coords:
            return tile_name
    return str(atlas_coords)


static func _create_tileset() -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = SysCfg.GRID_SIZE  # 格子按 32x32 定位
    ts.add_physics_layer()
    ts.set_physics_layer_collision_layer(0, 1)
    ts.set_physics_layer_collision_mask(0, 1)
    return ts


# 创建 source（仅配置，不含瓦片）
static func _create_source(path: String) -> TileSetAtlasSource:
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("TileSetPreset: 无法加载贴图: ", path)
        return TileSetAtlasSource.new()

    var source := TileSetAtlasSource.new()
    source.texture = texture
    source.texture_region_size = SysCfg.REGION_SIZE
    source.margins = SysCfg.TILE_MARGINS
    source.separation = SysCfg.TILE_SEPARATION
    return source


# 为一轴上的瓦片数量
static func _count(tex_len: int, margin: int, separation: int) -> int:
    var n := 0
    while margin + n * (SysCfg.REGION_SIZE.x + separation) + SysCfg.REGION_SIZE.x <= tex_len:
        n += 1
    return n


# 遍历创建所有瓦片；with_collision 为 false 时只创建图像，不生成碰撞体
static func _create_tiles(source: TileSetAtlasSource, source_name: String, with_collision: bool = true) -> void:
    var texture: Texture2D = source.texture
    var tex_size: Vector2i = texture.get_image().get_size()
    for y in _count(tex_size.y, SysCfg.TILE_MARGINS.y, SysCfg.TILE_SEPARATION.y):
        for x in _count(tex_size.x, SysCfg.TILE_MARGINS.x, SysCfg.TILE_SEPARATION.x):
            var coords := Vector2i(x, y)
            source.create_tile(coords)
            # 图集 48x48，地面内容在左下角 32x32。texture_origin 默认居中导致错位。
            # 统一对齐左下角：让 region 左下角对齐格子左下角。
            var tile_data := source.get_tile_data(coords, 0)
            tile_data.texture_origin = Vector2i(-8, 8)
            if with_collision:
                _set_tile_collision(source, texture, coords, source_name)


static func _set_tile_collision(source: TileSetAtlasSource, texture: Texture2D, coords: Vector2i, source_name: String) -> void:
    var region := Rect2i(SysCfg.TILE_MARGINS + coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    var image := texture.get_image().get_region(region)
    var entry := _get_or_build_shape(image, source_name)
    if entry.is_empty():
        return

    var tile_data: TileData = source.get_tile_data(coords, 0)
    # 默认应用 poly 碰撞体（与渲染对齐）
    var polygons: Array = entry.poly
    for i in polygons.size():
        tile_data.add_collision_polygon(0)
        tile_data.set_collision_polygon_points(0, i, polygons[i])


# 按形状哈希获取碰撞体形状。相同 hash 共享同一套 poly/rect。
# 返回 {seq, poly, rect}；若该形状无碰撞则返回空字典。
static func _get_or_build_shape(image: Image, source_name: String) -> Dictionary:
    var key := _hash_alpha(image)
    if _shape_cache.has(key):
        return _shape_cache[key]
    # 无碰撞体：alpha 为空，跳过（记录为空 shape，避免重复计算）
    if image.get_used_rect().size == Vector2i.ZERO:
        _shape_cache[key] = {}
        return {}
    var seq := _shape_seq_counter
    _shape_seq_counter += 1
    var entry := {
        "seq": seq,
        "poly": _build_polygons(image),
        "rect": _build_bounding_rect(image),
    }
    _shape_cache[key] = entry
    print("[TileSetPreset] 生成新形状 seq=", seq, " hash=", key, " source=", source_name)
    return entry


# 按图像生成最小外接矩形碰撞体（单个矩形，与渲染对齐）
static func _build_bounding_rect(image: Image) -> Array:
    var rect: Rect2i = image.get_used_rect()
    if rect.size == Vector2i.ZERO:
        return []
    var half := Vector2(SysCfg.REGION_SIZE) / 2.0
    var offset := Vector2(8, -8)  # 与 _build_polygons 对齐
    var top_left := Vector2(rect.position) - half + offset
    var size := Vector2(rect.size)
    return [PackedVector2Array([
        top_left,
        top_left + Vector2(size.x, 0),
        top_left + size,
        top_left + Vector2(0, size.y),
    ])]


# 根据瓦片图像生成 alpha>0 的位图（48x48），供掩码/碰撞复用
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


static func _build_polygons(image: Image) -> Array:
    var bit_map := build_alpha_bitmap(image)
    var result: Array = []
    var half := Vector2(SysCfg.REGION_SIZE) / 2.0
    # 碰撞体需与渲染对齐：渲染用 texture_origin=(-8,8)，碰撞体以其反向偏移校正(向右上移 8,8)
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


# 仅对 alpha 通道哈希，颜色不同但形状相同的瓦片共享碰撞体
static func _hash_alpha(image: Image) -> String:
    image.convert(Image.FORMAT_LA8)  # 每像素2字节，alpha 在奇数索引
    var data := image.get_data()
    @warning_ignore("integer_division")
    var n: int = data.size() / 2
    var alpha := PackedByteArray()
    alpha.resize(n)
    for i in n:
        alpha[i] = data[i * 2 + 1]
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_MD5)
    ctx.update(alpha)  # 一次 update，避免逐字节调用开销
    return ctx.finish().hex_encode()
