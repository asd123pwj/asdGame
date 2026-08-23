class_name TMapSys
extends RefCounted

static var maps_parent_node: Node2D = Node2D.new()
static var maps: Dictionary[int, TileMapLayer] = {}
static var maps_canvas: Dictionary[int, CanvasLayer] = {}
const P3D_OFFSET := Vector2(0, 16)
# 记录每个 tilemap 层里每个格子放的 source_name，供 P3D 查询邻居
static var _tile_sources: Dictionary = {}
# 擦除掩码缓存：key = 当前+三邻居的 source_name 组合，value = 擦除掩码纹理
static var _erase_cache: Dictionary = {}
# P3D 擦除掩码 shader
static var _erase_shader: Shader = load("res://Shader/sprite_mask.gdshader")


func _init() -> void:
    Sys.sys.add_child(maps_parent_node)

    var id = map_layer_to_id(0, Enums.LayerType.MIDDLE)
    create_tilemap(id)
    create_P3D_canvas(id-1)
    for i in range(0, 4):
        for j in range(0, 4):
            place_tile(id, i, j, "P3D")
            place_tile(id, i+5, j+1, "White Wall")
            place_tile(id, i+1, j+5+1, "透明玻璃")
            place_tile(id, i+5+1, j+5+1, "完整玻璃")
            place_tile(id, i+10+1, j+5+1, "完整玻璃-反")
    for i in range(0, 4):
        for j in range(0, 4):
            place_p3d_sprite(id-1, i, j, "P3D")
            place_p3d_sprite(id-1, i+5, j+1, "White Wall")
            place_p3d_sprite(id-1, i+1, j+5+1, "透明玻璃")
            place_p3d_sprite(id-1, i+5+1, j+5+1, "完整玻璃")
            place_p3d_sprite(id-1, i+10+1, j+5+1, "完整玻璃-反")


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]

static func place_tile_with_P3D(id: int, x: int, y: int, source_name: String) -> void:
    place_tile(id, x, y, source_name)
    place_p3d_sprite(id-1, x, y, source_name)

static func place_tile(id: int, x: int, y: int, source_name: String) -> void:
    var source_id: int = TileSetPreset.get_source_id(source_name)
    maps[id].set_cell(Vector2i(x, y), source_id, Vector2i(0, 2))
    if not _tile_sources.has(id):
        _tile_sources[id] = {}
    _tile_sources[id][Vector2i(x, y)] = source_name


# 获取当前 tile 及其三个遮挡邻居(上/右上/右)的内容擦除掩码纹理(48x48)
# 结果按 source 组合缓存复用
static func get_erase_mask(tilemap_id: int, x: int, y: int, source_name: String) -> ImageTexture:
    var sources := _get_neighbor_sources(tilemap_id, x, y)
    var key := String(source_name) + "|" + str(sources[0]) + "|" + str(sources[1]) + "|" + str(sources[2])
    if _erase_cache.has(key):
        return _erase_cache[key]
    var img := _build_erase_mask(tilemap_id, x, y, sources)
    # 调试：检查掩码图像是否有红色像素
    var red_count := 0
    for py in 48:
        for px in 48:
            var c := img.get_pixel(px, py)
            if c.r > 0.5:
                red_count += 1
    print("[debug] 掩码 key=", key, " 红色像素=", red_count, " 尺寸=", img.get_size())
    # 调试：把擦除掩码保存为 PNG，文件名用缓存名，便于检查掩码是否正确
    var dir := "res://Debug"
    DirAccess.make_dir_recursive_absolute(dir)
    img.save_png(dir + "/" + _safe_filename(key) + ".png")
    var tex := ImageTexture.create_from_image(img)
    _erase_cache[key] = tex
    return tex


# 把缓存名转为安全文件名（替换路径中不合法的字符）
static func _safe_filename(name: String) -> String:
    return name.replace("/", "_").replace("\\", "_").replace(":", "_").replace("*", "_") \
        .replace("?", "_").replace("\"", "_").replace("<", "_").replace(">", "_").replace("|", "_")


# 获取当前 tile 及三个遮挡邻居的 source_name（无 tile 返回空串）
static func _get_neighbor_sources(tilemap_id: int, x: int, y: int) -> Array:
    var cells: Dictionary = _tile_sources.get(tilemap_id, {})
    var up: String = cells.get(Vector2i(x, y - 1), "")
    var up_right: String = cells.get(Vector2i(x + 1, y - 1), "")
    var right: String = cells.get(Vector2i(x + 1, y), "")
    return [up, up_right, right]


# 把三个邻居内容矩阵合并成 48x48 的擦除掩码，偏移到当前 P3D 精灵局部坐标系
static func _build_erase_mask(_tilemap_id: int, x: int, y: int, sources: Array) -> Image:
    var img := Image.create(48, 48, false, Image.FORMAT_RGB8)
    img.fill(Color(0, 0, 0))
    var origin := Vector2(x * 32, y * 32) - P3D_OFFSET  # P3D 精灵左上角世界坐标
    # 三个邻居相对格子的方向
    var neighbor_cells: Array[Vector2i] = [
        Vector2i(x, y - 1),       # 上
        Vector2i(x + 1, y - 1),   # 右上
        Vector2i(x + 1, y),       # 右
    ]
    for i in 3:
        var nsrc: String = sources[i]
        if nsrc.is_empty():
            continue
        var matrix := TileSetPreset.get_content_matrix(nsrc)
        var nc: Vector2i = neighbor_cells[i]
        # tile 经 texture_origin 左下角对齐后，region 左上角与 P3D 精灵一致：
        # = (格子坐标 * 32) - P3D_OFFSET
        var nbase := Vector2(nc.x * 32, nc.y * 32) - P3D_OFFSET
        for my in 48:
            for mx in 48:
                if not matrix.get_bit(mx, my):
                    continue
                var lx := int(nbase.x + mx - origin.x)
                var ly := int(nbase.y + my - origin.y)
                if lx >= 0 and lx < 48 and ly >= 0 and ly < 48:
                    img.set_pixel(lx, ly, Color(1, 0, 0))
    return img


static func place_p3d_sprite(id: int, x: int, y: int, source_name: String) -> void:
    var sprite := TileSetPreset.create_p3d_sprite(source_name, Vector2i(0, 2))
    # 定位到格子左上角，并补偿伪3D内容在瓦片内的偏移
    sprite.position = Vector2(x * 32, y * 32) - P3D_OFFSET
    sprite.name = str(x) + "," + str(y)
    sprite.z_index = x - y
    # P3D 遮挡擦除：查询邻居 tile，生成擦除掩码纹理并传给 shader
    var mat := ShaderMaterial.new()
    mat.shader = _erase_shader
    mat.set_shader_parameter("erase_mask", get_erase_mask(id + 1, x, y, source_name))
    mat.set_shader_parameter("mode", 1)  # 0=置红可视化，1=删除挖空
    # 计算 region 在 atlas 图中的 UV 偏移和缩放，供 shader 把 atlas UV 转成精灵内局部 UV
    var atlas := sprite.texture as AtlasTexture
    if atlas != null and atlas.atlas != null:
        var atlas_size := atlas.atlas.get_size()
        mat.set_shader_parameter("region_offset", atlas.region.position / atlas_size)
        mat.set_shader_parameter("region_scale", atlas.region.size / atlas_size)
    sprite.material = mat
    maps_canvas[id].add_child(sprite)

static func create_P3D_canvas(id: int) -> void:
    maps_canvas[id] = CanvasLayer.new()
    maps_canvas[id].name = "Canvas " + map_id_to_name(id)
    maps_canvas[id].layer = id
    maps_parent_node.add_child(maps_canvas[id])

static func create_tilemap(id: int) -> void:
    var tileset: TileSet = TileSetPreset.tileset
    maps[id] = TileMapLayer.new()
    maps[id].name = map_id_to_name(id)
    # 对齐已由 TileSetPreset 的 texture_origin 处理，不再需要整体偏移
    maps[id].position = Vector2(0, 0)
    # maps[id].collision_visibility_mode = TileMapLayer.DebugVisibilityMode.DEBUG_VISIBILITY_MODE_FORCE_SHOW
    maps[id].tile_set = TileSetPreset.tileset
    maps_canvas[id] = CanvasLayer.new()
    maps_canvas[id].name = "Canvas " + map_id_to_name(id)
    maps_canvas[id].layer = id
    maps_canvas[id].add_child(maps[id])
    maps_parent_node.add_child(maps_canvas[id])