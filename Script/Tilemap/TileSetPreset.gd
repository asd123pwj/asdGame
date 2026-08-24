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
static var _collision_cache: Dictionary = {}
# P3D 图集缓存："name|atlas_coords" -> AtlasTexture（纯资源可共享）
static var _atlas_cache: Dictionary = {}

# ---- tile id 注册表 ----
# 列表：序号即 tile id，每个元素为 [source_name, atlas_coords]
static var _tile_id_list: Array = []
# 映射："source_name|coords" -> tile id(序号)
static var _tile_id_map: Dictionary = {}
# tile 名称映射：source_name -> tile_name -> atlas_coords（基于 rule.tiles_name）
static var _tile_name_coords: Dictionary = {}

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
    return id


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
    var polygons := _get_or_build_polygons(texture.get_image().get_region(region), source_name)
    if polygons.is_empty():
        return

    var tile_data: TileData = source.get_tile_data(coords, 0)
    for i in polygons.size():
        tile_data.add_collision_polygon(0)
        tile_data.set_collision_polygon_points(0, i, polygons[i])


# 基于 alpha 生成多边形，按哈希缓存复用
static func _get_or_build_polygons(image: Image, _source_name: String) -> Array:
    var key := _hash_alpha(image)
    if _collision_cache.has(key):
        return _collision_cache[key]
    var polygons := _build_polygons(image)
    # print("[TileSetPreset] 缓存未命中, source=", _source_name, ", 瓦片哈希: ", key)
    _collision_cache[key] = polygons
    return polygons


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
