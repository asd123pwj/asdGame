class_name TileSetPreset
extends PresetRegister

var name: String
var layer: Enums.LayerType
var region_size: int
var tile_match_rule_name: String
var path: String
var path_P3D: String
# 放置规则：该 source 放置时需满足的需求九宫格名称列表（多个为 and）
var place_rule_names: Array = []

var source: TileSetAtlasSource
var source_id: int
var source_P3D: TileSetAtlasSource
var source_id_P3D: int

static var _we: Dictionary[String, TileSetPreset] = {}
static var tileset: TileSet = _create_tileset()
# P3D 瓦片定位校正（texture_origin）。初始值反推自"P3D 显示偏移"，运行后可微调。
# static var P3D_TILE_ORIGIN := Vector2i(-8, 8)

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

func _init(name: String, layer: Enums.LayerType, region_size:int, tile_match_rule_name: String, path: String, place_rule_names: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.layer = layer
    self.region_size = region_size
    self.tile_match_rule_name = tile_match_rule_name
    self.path = path
    self.place_rule_names = place_rule_names
    if layer == Enums.LayerType.MIDDLE:
        self.path_P3D = path.get_basename() + "_P3D." + path.get_extension()
 
    source = _create_source(path, region_size)
    source_id = tileset.add_source(source)
    # 仅 Middle 层有碰撞体
    _create_tiles(source, name, layer == Enums.LayerType.MIDDLE)

    # 仅 Middle 层有 P3D 素材
    if layer == Enums.LayerType.MIDDLE:
        source_P3D = _create_source(path_P3D, region_size)
        source_id_P3D = tileset.add_source(source_P3D)
        _create_tiles(source_P3D, name, false)  # P3D source：只显示图像，无碰撞体

    # 为各位置 tile 命名（有规则用 tiles_name；无规则用 "x,y"）
    _build_tile_name_map(name)
    if false:
        save_all_tiles_debug()


static func get_(name: String) -> TileSetPreset:
    return _we[name]


static func get_source_id(name: String) -> int:
    return _we[name].source_id


static func get_source_id_P3D(name: String) -> int:
    return _we[name].source_id_P3D


# 基于匹配规则的 tiles_name 建立 tile_name -> 子tile组结构 映射。
# 结构：{base_cols:int, variant_count:int, parts:[{grow,gcol,coords}, ...]}
static func _build_tile_name_map(source_name: String) -> void:
    var rule := TileMatchRulePreset.get_(_we[source_name].tile_match_rule_name)
    var map: Dictionary = {}
    if rule == null or rule.tiles_name.is_empty():
        # 无规则：用 "x,y" 命名所有图集位置
        _map_all_coords_as_xy(source_name, map)
    else:
        _parse_tiles_name(source_name, rule.tiles_name, map)
    _tile_name_coords[source_name] = map


# 解析 tiles_name 生成 tile_name -> 子tile组 映射。
# 元素可为 String（该位置 tile 名）或 Array（[组名, [组内行, 组内列]]，一组多格共用组名）。
# 变种：该组基础列数为一行元素数，图片多出的列按基础列循环作为变种。
# 空格跳过：整个 tile 的所有子tile 对应格都为空则跳过该 tile。
static func _parse_tiles_name(source_name: String, tiles_name: Array, map: Dictionary) -> void:
    var total_cols := _get_source_column_count(source_name)
    var groups: Dictionary = {}
    for row in tiles_name.size():
        var row_names: Array = tiles_name[row]
        var base_cols := row_names.size()
        if base_cols == 0:
            continue
        for col in base_cols:
            var cell = row_names[col]
            var tile_name: String
            var grow: int = 1
            var gcol: int = 1
            if cell is Array:
                tile_name = cell[0]
                grow = cell[1][0]
                gcol = cell[1][1]
            else:
                tile_name = str(cell)
            if tile_name.is_empty():
                continue
            if not groups.has(tile_name):
                groups[tile_name] = {"base_cols": base_cols, "cells": []}
            var gd: Dictionary = groups[tile_name]
            var cells: Array = gd.cells
            cells.append({
                "grow": grow, "gcol": gcol,
                "coords": Vector2i(col, row),
            })
    # 一次性取 source 图像（避免每个格都 get_image 复制整图，降低加载耗时）
    var src_img := _we[source_name].source.texture.get_image()
    for tile_name in groups:
        var g: Dictionary = groups[tile_name]
        var base_cols: int = g.base_cols
        @warning_ignore("integer_division")
        var total_variants := maxi(1, total_cols / base_cols)
        # 逐变种列判空：只保留整列（所有子tile）都不空的变种，空变种跳过
        var valid_variants: Array = []
        for v in total_variants:
            if not _is_variant_empty(src_img, g.cells, v, base_cols):
                valid_variants.append(v)
        if valid_variants.is_empty():
            continue
        map[tile_name] = {
            "base_cols": base_cols,
            "variant_count": valid_variants.size(),
            "variant_cols": valid_variants,
            "parts": g.cells,
        }


# 判断某变种列（v）的所有子tile 格是否全空（该变种无效则跳过）。src_img 为整个图集图像。
static func _is_variant_empty(src_img: Image, cells: Array, v: int, base_cols: int) -> bool:
    for cell in cells:
        var coords: Vector2i = cell.coords + Vector2i(v * base_cols, 0)
        if not _is_cell_empty(src_img, coords):
            return false
    return true


# 判断某 atlas 格是否为空（alpha 全空）。src_img 为整个图集图像。
static func _is_cell_empty(src_img: Image, coords: Vector2i) -> bool:
    var region := Rect2i(SysCfg.TILE_MARGINS + coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    return src_img.get_region(region).get_used_rect().size == Vector2i.ZERO


# 无规则 source：按图集行列数用 "x,y" 命名（每格单 tile，无变种）
static func _map_all_coords_as_xy(source_name: String, map: Dictionary) -> void:
    var tex := _we[source_name].source.texture
    if tex == null:
        return
    var tex_size: Vector2i = tex.get_image().get_size()
    var cols := _count(tex_size.x, SysCfg.TILE_MARGINS.x, SysCfg.TILE_SEPARATION.x)
    var rows := _count(tex_size.y, SysCfg.TILE_MARGINS.y, SysCfg.TILE_SEPARATION.y)
    for row in rows:
        for col in cols:
            map[str(col) + "," + str(row)] = {
                "base_cols": 1,
                "variant_count": 1,
                "parts": [{"grow": 1, "gcol": 1, "coords": Vector2i(col, row)}],
            }


# 获取 source 图集的列数（按 REGION_SIZE 网格分块）
static func _get_source_column_count(source_name: String) -> int:
    var tex := _we[source_name].source.texture
    if tex == null:
        return 1
    return _count(tex.get_image().get_size().x, SysCfg.TILE_MARGINS.x, SysCfg.TILE_SEPARATION.x)


# 按 tile 名称获取基础变种第一个子tile 的 atlas_coords，找不到返回 Vector2i(-1, -1)
static func get_tile_coords_by_name(source_name: String, tile_name: String) -> Vector2i:
    var group: Dictionary = get_tile_group(source_name, tile_name)
    if group.is_empty():
        return Vector2i(-1, -1)
    return group.parts[0].coords


# 获取 source 下某 tile 名称的子tile 组结构 {base_cols, variant_count, parts}；不存在返回空字典
static func get_tile_group(source_name: String, tile_name: String) -> Dictionary:
    var map: Dictionary = _tile_name_coords.get(source_name, {})
    var g = map.get(tile_name)
    return g if g is Dictionary else {}


# 获取某 tile 名称在指定变种下的所有子tile。
# 每个子tile：{coords: Vector2i, dx: int, dy: int}（dx/dy 为相对组左下角(1,1)的偏移，逻辑 y 向上为正）
# variant 是有效变种索引（variant_cols 中的序号），越界时回退到基础变种 0。
static func get_tile_parts(source_name: String, tile_name: String, variant: int = 0) -> Array:
    var group: Dictionary = get_tile_group(source_name, tile_name)
    if group.is_empty():
        return []
    var base_cols: int = group.base_cols
    var vcols: Array = group.get("variant_cols", [])
    if vcols.is_empty():
        vcols = [0]
    var vi := clampi(variant, 0, vcols.size() - 1)
    var vcol: int = vcols[vi]
    var parts: Array = []
    for p in group.parts:
        var coords: Vector2i = p.coords + Vector2i(vcol * base_cols, 0)
        parts.append({
            "coords": coords,
            "dx": p.gcol - 1,
            "dy": p.grow - 1,
        })
    return parts


# 获取 source 是否配置了匹配规则名
static func has_match_rule(source_name: String) -> bool:
    return _we[source_name].tile_match_rule_name != ""


# 判断 source 是否存在指定 tile 名称
static func has_tile_name(source_name: String, tile_name: String) -> bool:
    var map: Dictionary = _tile_name_coords.get(source_name)
    return map != null and map.has(tile_name)


# 判断某 source 的某 tile 是否具有指定 tag（tag 匹配 tile_name 或 source_name）
static func has_tag(source_name: String, tile_name: String, tag: String) -> bool:
    return tile_name == tag or source_name == tag


# 获取 source 放置时需满足的需求九宫格名称列表
static func get_place_rule_names(source_name: String) -> Array:
    return _we[source_name].place_rule_names


# 获取 source 的默认 tile 名称（tiles_name 的 (0,0) 位置的 tile 名；无规则则用 "0,0"）
static func get_default_tile_name(source_name: String) -> String:
    var rule: TileMatchRulePreset = TileMatchRulePreset.get_(_we[source_name].tile_match_rule_name)
    if rule == null or rule.tiles_name.is_empty():
        # 无规则 source：默认 "x,y" 命名的 (0,0)
        return str(0) + "," + str(0)
    var first_row: Array = rule.tiles_name[0]
    if first_row.is_empty():
        return str(0) + "," + str(0)
    var cell = first_row[0]
    # cell 可能为 Array（[组名, [行, 列]]）或 String
    return cell[0] if cell is Array else str(cell)


# 获取/注册 (source_name, tile_name, variant) 的 tile id（列表序号）。tile 与 P3D 共用一个 id。
# variant 越界时自动取该 tile 的变种数范围内，保证唯一注册。
static func get_or_register_tile_id(source_name: String, tile_name: String, variant: int = 0) -> int:
    var group := get_tile_group(source_name, tile_name)
    var v := 0
    if not group.is_empty():
        v = clampi(variant, 0, group.variant_count - 1)
    var key := source_name + "|" + tile_name + "|" + str(v)
    if _tile_id_map.has(key):
        return _tile_id_map[key]
    var id := _tile_id_list.size()
    _tile_id_list.append([source_name, tile_name, v])
    _tile_id_map[key] = id
    # 记录该 tile 的形状哈希（tile 与 P3D 共用 id，这里记录的是 tile 图集形状）
    _tile_hash_cache[id] = get_tile_shape_hash(source_name, tile_name, v)
    return id


# 获取指定 tile（source_name + tile_name + variant）的形状哈希（基于 tile 图集 alpha 首个子tile）。
static func get_tile_shape_hash(source_name: String, tile_name: String, variant: int = 0) -> String:
    var parts := get_tile_parts(source_name, tile_name, variant)
    if parts.is_empty():
        return ""
    return _hash_alpha(get_region_image(source_name, parts[0].coords, false))


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


# 按 tile id 获取 [source_name, tile_name, variant]
static func get_tile_id_info(id: int) -> Array:
    return _tile_id_list[id]


# 把 [source_name, tile_name, variant] 转为 atlas_coords（取该变种第一个子tile，需要 atlas 时用）
static func get_tile_info_coords(info: Array) -> Vector2i:
    var parts := get_tile_parts_by_info(info)
    if parts.is_empty():
        return Vector2i(-1, -1)
    return parts[0].coords


# 按 tile id 获取该 tile 所有子tile（含 dx/dy 组内偏移与 coords）；未注册或无效返回空
static func get_tile_parts_by_id(tile_id: int) -> Array:
    if tile_id < 0 or tile_id >= _tile_id_list.size():
        return []
    return get_tile_parts_by_info(_tile_id_list[tile_id])


# 按 info [source_name, tile_name, variant] 获取所有子tile（含 dx/dy 组内偏移与 coords）
static func get_tile_parts_by_info(info: Array) -> Array:
    var variant: int = info[2] if info.size() > 2 else 0
    return get_tile_parts(info[0], info[1], variant)


# 获取指定 source 的图集 region 图像（48x48）。
# is_p3d 为 true 取 P3D 图集(source_P3D)，否则取 tile 图集(source)。
# 若 source 无 P3D（如 Plant 组素材），is_p3d 时返回全透明图像（安全）。
static func get_region_image(source_name: String, atlas_coords: Vector2i, is_p3d: bool) -> Image:
    var preset := _we[source_name]
    var src := preset.source_P3D if is_p3d else preset.source
    if src == null:
        # 无该图集（尤其 P3D 不存在）：返回全透明 48x48 图像
        var empty := Image.create(SysCfg.REGION_SIZE.x, SysCfg.REGION_SIZE.y, false, Image.FORMAT_RGBA8)
        empty.fill(Color(0, 0, 0, 0))
        return empty
    var region := Rect2i(SysCfg.TILE_MARGINS + atlas_coords * (SysCfg.REGION_SIZE + SysCfg.TILE_SEPARATION), SysCfg.REGION_SIZE)
    return src.texture.get_image().get_region(region)


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
    td.texture_origin = SysCfg.P3D_TILE_ORIGIN

    var info := {"source_id": source_id, "atlas_coords": Vector2i(0, 0)}
    if not _p3d_mask_variant_cache.has(tile_id):
        _p3d_mask_variant_cache[tile_id] = {}
    _p3d_mask_variant_cache[tile_id][neighbor_key] = info
    return info


# 从 atlas_coords 反查 tile_name（用于掩码变体注册时的 tile_id）
static func tile_name_from_coords(source_name: String, atlas_coords: Vector2i) -> String:
    for tile_name in _tile_name_coords.get(source_name, {}):
        var group: Dictionary = _tile_name_coords[source_name][tile_name]
        for p in group.parts:
            if p.coords == atlas_coords:
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
# region_size 与原图一致（48）则直接用；若小于 48（如 32），先把图集预处理成 48x48 版本再使用。
static func _create_source(path: String, region_size: int) -> TileSetAtlasSource:
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("TileSetPreset: 无法加载贴图: ", path)
        return TileSetAtlasSource.new()

    var img: Image = texture.get_image()
    if region_size != SysCfg.REGION_SIZE.x:
        # 预处理：按 region_size 切分，重排为 48x48 网格（内容放 48x48 左下角）
        img = _to_48_atlas(img, region_size)
        # Debug：保存预处理后的 48x48 图集，便于检查 32→48 重排是否正确（用时改 if true）
        if false:
            _save_debug_png(img, path.get_file().get_basename() + "_48.png")

    var source := TileSetAtlasSource.new()
    source.texture = ImageTexture.create_from_image(img)
    source.texture_region_size = SysCfg.REGION_SIZE
    source.margins = SysCfg.TILE_MARGINS
    source.separation = SysCfg.TILE_SEPARATION
    return source


# 把按 region_size 网格切分的原图重排为 48x48 网格图集：每块 region_size 内容放到 48x48 左下角。
# 这样后续所有处理（碰撞、掩码、texture_origin 等）都能按 48x48 统一进行。
static func _to_48_atlas(image: Image, region_size: int) -> Image:
    var rsize := region_size
    @warning_ignore("integer_division")
    var cols := image.get_width() / rsize
    @warning_ignore("integer_division")
    var rows := image.get_height() / rsize
    var out := Image.create(
        cols * SysCfg.REGION_SIZE.x, rows * SysCfg.REGION_SIZE.y,
        false, image.get_format())
    out.fill(Color(0, 0, 0, 0))  # 必须先填充全透明，否则未覆盖区域不透明，判空会误判
    var dy := SysCfg.REGION_SIZE.y - rsize  # 48x48 内左下角对齐的 y 偏移
    for cy in rows:
        for cx in cols:
            var src_rect := Rect2i(cx * rsize, cy * rsize, rsize, rsize)
            out.blit_rect(image, src_rect,
                Vector2i(cx * SysCfg.REGION_SIZE.x, cy * SysCfg.REGION_SIZE.y + dy))
    return out


# 把图像保存到 Debug 目录（file_name 为完整文件名，含 .png），便于人工检查
static func _save_debug_png(image: Image, file_name: String) -> void:
    var debug_path: String = SysCfg.DEBUG_DIR + file_name
    DirAccess.make_dir_recursive_absolute(SysCfg.DEBUG_DIR)
    if image.save_png(debug_path) != OK:
        push_error("TileSetPreset: 保存调试图像失败: ", debug_path)


# 把所有 tile（所有 source、所有 tile 名、所有变种、所有子tile）保存到 Debug 目录。
# 文件名包含：source、tile 名、组内位置（行,列）、变种号。
static func save_all_tiles_debug() -> void:
    for source_name in _tile_name_coords:
        var map: Dictionary = _tile_name_coords[source_name]
        for tile_name in map:
            var group: Dictionary = map[tile_name]
            var base_cols: int = group.base_cols
            var vcols: Array = group.get("variant_cols", [0])
            var parts: Array = group.parts
            for i in vcols.size():
                var vcol: int = vcols[i]
                for part in parts:
                    var pd: Dictionary = part
                    var coords: Vector2i = pd.coords + Vector2i(vcol * base_cols, 0)
                    var img := get_region_image(source_name, coords, false)
                    var file_name := "%s_%s_g%d_%d_v%d.png" % [
                        source_name, tile_name, pd.grow, pd.gcol, i]
                    _save_debug_png(img, file_name)


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
    if false:
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
