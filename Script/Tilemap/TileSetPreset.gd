class_name TileSetPreset
extends PresetRegister

var name: String
var path: String
var path_P3D: String

var source: TileSetAtlasSource
var source_id: int
var source_P3D: TileSetAtlasSource
var source_id_P3D: int

static var _we: Dictionary[String, TileSetPreset] = {}
static var tileset: TileSet = _create_tileset()
static var _collision_cache: Dictionary = {}

# 图集切割尺寸（48x48 网格，含伪3D外部16像素）
const REGION_SIZE := Vector2i(48, 48)
# 显示格子尺寸（32x32 定位，伪3D溢出到相邻格）
const GRID_SIZE := Vector2i(32, 32)
const TILE_MARGINS := Vector2i(0, 0)
const TILE_SEPARATION := Vector2i(0, 0)


func _init(name: String, path: String, path_P3D: String) -> void:
    _we[name] = self
    self.name = name
    self.path = path
    self.path_P3D = path_P3D

    source = _create_source(path)
    source_id = tileset.add_source(source)
    _create_tiles(source, name, true)  # 正常 source：有碰撞体

    source_P3D = _create_source(path_P3D)
    source_id_P3D = tileset.add_source(source_P3D)
    _create_tiles(source_P3D, name, false)  # P3D source：只显示图像，无碰撞体


static func get_(name: String) -> TileSetPreset:
    return _we[name]


static func get_source_id(name: String) -> int:
    return _we[name].source_id


static func get_source_id_P3D(name: String) -> int:
    return _we[name].source_id_P3D


# 为指定瓦片创建伪3D精灵（Sprite2D + AtlasTexture）
# 用 Node2D 的 y_sort 控制遮挡，避免 TileMap 排序限制
static func create_p3d_sprite(name: String, atlas_coords: Vector2i) -> Sprite2D:
    var preset := _we[name]
    var texture: Texture2D = load(preset.path_P3D)
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    var region := Rect2(TILE_MARGINS + atlas_coords * (REGION_SIZE + TILE_SEPARATION), REGION_SIZE)
    atlas.region = region
    var sprite := Sprite2D.new()
    sprite.texture = atlas
    sprite.centered = false  # 锚点左上角，便于按瓦片网格定位
    return sprite


static func _create_tileset() -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = GRID_SIZE  # 格子按 32x32 定位
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
    source.texture_region_size = REGION_SIZE
    source.margins = TILE_MARGINS
    source.separation = TILE_SEPARATION
    return source


# 为一轴上的瓦片数量
static func _count(tex_len: int, margin: int, separation: int) -> int:
    var n := 0
    while margin + n * (REGION_SIZE.x + separation) + REGION_SIZE.x <= tex_len:
        n += 1
    return n


# 遍历创建所有瓦片；with_collision 为 false 时只创建图像，不生成碰撞体
static func _create_tiles(source: TileSetAtlasSource, source_name: String, with_collision: bool = true) -> void:
    var texture: Texture2D = source.texture
    var tex_size: Vector2i = texture.get_image().get_size()
    for y in _count(tex_size.y, TILE_MARGINS.y, TILE_SEPARATION.y):
        for x in _count(tex_size.x, TILE_MARGINS.x, TILE_SEPARATION.x):
            var coords := Vector2i(x, y)
            source.create_tile(coords)
            if with_collision:
                _set_tile_collision(source, texture, coords, source_name)


static func _set_tile_collision(source: TileSetAtlasSource, texture: Texture2D, coords: Vector2i, source_name: String) -> void:
    var region := Rect2i(TILE_MARGINS + coords * (REGION_SIZE + TILE_SEPARATION), REGION_SIZE)
    var polygons := _get_or_build_polygons(texture.get_image().get_region(region), source_name)
    if polygons.is_empty():
        return

    var tile_data: TileData = source.get_tile_data(coords, 0)
    for i in polygons.size():
        tile_data.add_collision_polygon(0)
        tile_data.set_collision_polygon_points(0, i, polygons[i])


# 基于 alpha 生成多边形，按哈希缓存复用
static func _get_or_build_polygons(image: Image, source_name: String) -> Array:
    var key := _hash_alpha(image)
    if _collision_cache.has(key):
        return _collision_cache[key]
    var polygons := _build_polygons(image)
    print("[TileSetPreset] 缓存未命中, source=", source_name, ", 瓦片哈希: ", key)
    _collision_cache[key] = polygons
    return polygons


static func _build_polygons(image: Image) -> Array:
    var bit_map := BitMap.new()
    bit_map.create(Vector2i(REGION_SIZE.x, REGION_SIZE.y))
    # 阈值设为 alpha > 0：只要有内容就阻挡（半透明玻璃也生成碰撞）
    var alpha_img: Image = image.duplicate()
    alpha_img.convert(Image.FORMAT_LA8)
    var data := alpha_img.get_data()
    @warning_ignore("integer_division")
    for idx in data.size() / 2:
        if data[idx * 2 + 1] > 0:
            bit_map.set_bit(idx % REGION_SIZE.x, floori(float(idx) / REGION_SIZE.x), true)
    var result: Array = []
    var half := Vector2(REGION_SIZE) / 2.0
    for raw in bit_map.opaque_to_polygons(Rect2(Vector2.ZERO, REGION_SIZE)):
        var points: PackedVector2Array = raw
        if points.size() > 3 and points[0] == points[points.size() - 1]:
            points.remove_at(points.size() - 1)
        if points.size() >= 3:
            for i in points.size():
                points[i] -= half
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
