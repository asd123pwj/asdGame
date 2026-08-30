class_name TileSetPreset
extends PresetRegister

# 一个 tile 集合：由多个 TileSpritePreset（素材）组成。
# tile_name 由 match_rule 的 tiles_name 解析（tile_name → 行列 + 多格子），
# 其变种 = 各素材同名 tile_name 变种的拼接（一个 tile 的所有子格来自同一素材）。

var name: String
var layer: Enums.LayerType
var tile_match_rule_name: String
var sprites_name: Array = []
var place_rule_names: Array = []

static var _we: Dictionary[String, TileSetPreset] = {}
# tile 定义：set_name -> tile_name -> {base_cols, parts:[{grow,gcol,coords}]}
static var _tile_defs: Dictionary = {}
# tile_id 注册：_tile_id_list[id] = [set_name, tile_name, variant]；variant 是跨素材变种索引
static var _tile_id_list: Array = []
static var _tile_id_map: Dictionary = {}
static var _tile_hash_cache: Dictionary = {}
# P3D 掩码变体缓存：sprite+coords+掩码 -> {source_id, atlas_coords}
static var _p3d_mask_variant_cache: Dictionary = {}


func _init(name: String, layer: Enums.LayerType, tile_match_rule_name: String,
        sprites_name: Array, place_rule_names: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.layer = layer
    self.tile_match_rule_name = tile_match_rule_name
    self.sprites_name = sprites_name
    self.place_rule_names = place_rule_names
    _build_tile_defs(name)


static func get_(name: String) -> TileSetPreset:
    return _we[name]


# 解析 match_rule 的 tiles_name，建立 tile_name -> 行列定义（不依赖具体素材）
static func _build_tile_defs(set_name: String) -> void:
    var rule := TileMatchRulePreset.get_(_we[set_name].tile_match_rule_name)
    var defs: Dictionary = {}
    if rule != null and not rule.tiles_name.is_empty():
        _parse_tiles_name(set_name, rule.tiles_name, defs)
    _tile_defs[set_name] = defs


static func _parse_tiles_name(_set_name: String, tiles_name: Array, defs: Dictionary) -> void:
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
            if not defs.has(tile_name):
                defs[tile_name] = {"base_cols": base_cols, "parts": []}
            var d: Dictionary = defs[tile_name]
            var parts: Array = d.parts
            parts.append({
                "grow": grow, "gcol": gcol,
                "coords": Vector2i(col, row),
            })


# tile_name 是否存在（解析自 match_rule 的 tiles_name）
static func has_tile_name(set_name: String, tile_name: String) -> bool:
    var defs: Dictionary = _tile_defs.get(set_name, {})
    return defs.has(tile_name)


static func get_tile_def(set_name: String, tile_name: String) -> Dictionary:
    var defs: Dictionary = _tile_defs.get(set_name, {})
    # 懒重建：若首次注册时 match_rule 尚未就绪导致 defs 为空，且现在规则已可用则重建
    if defs.is_empty() and TileMatchRulePreset.get_(_we[set_name].tile_match_rule_name) != null:
        _build_tile_defs(set_name)
        defs = _tile_defs.get(set_name, {})
    var d = defs.get(tile_name)
    return d if d is Dictionary else {}


# 某素材下该 tile_name 的有效变种列（判空跳过全空的变种列）
static func _sprite_variant_cols(set_name: String, tile_name: String, sprite_name: String) -> Array:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return []
    var base_cols: int = def.base_cols
    @warning_ignore("integer_division")
    var total_v := maxi(1, TileSpritePreset.get_column_count(sprite_name) / base_cols)
    var vcols: Array = []
    for v in total_v:
        if not _is_variant_empty(sprite_name, def.parts, v, base_cols):
            vcols.append(v)
    return vcols


static func _is_variant_empty(sprite_name: String, parts: Array, v: int, base_cols: int) -> bool:
    for p in parts:
        var coords: Vector2i = p.coords + Vector2i(v * base_cols, 0)
        if not TileSpritePreset.is_cell_empty(sprite_name, coords, false):
            return false
    return true


# 该 tile_name 跨素材的总变种数
static func get_tile_variant_count(set_name: String, tile_name: String) -> int:
    var c := 0
    for sp in _we[set_name].sprites_name:
        c += _sprite_variant_cols(set_name, tile_name, sp).size()
    return c


# Debug：打印各素材下某 tile 的变种数（定位跨素材随机性问题）
static func debug_variant_counts(set_name: String, tile_name: String) -> void:
    for sp in _we[set_name].sprites_name:
        var vcols := _sprite_variant_cols(set_name, tile_name, sp)
        print("[TileSetPreset] ", set_name, "/", tile_name, " sprite=", sp,
            " cols=", TileSpritePreset.get_column_count(sp),
            " vcols=", vcols)


# 变种索引 → [sprite_name, 该素材内的实际列号]
static func _resolve_variant(set_name: String, tile_name: String, variant: int) -> Array:
    var v := variant
    for sp in _we[set_name].sprites_name:
        var vcols := _sprite_variant_cols(set_name, tile_name, sp)
        if v < vcols.size():
            return [sp, vcols[v]]
        v -= vcols.size()
    var sp_last: String = _we[set_name].sprites_name[-1]
    var last_cols := _sprite_variant_cols(set_name, tile_name, sp_last)
    return [sp_last, last_cols[maxi(0, last_cols.size() - 1)]]


# 获取某 tile 变种的所有子tile（含 source_id）。供渲染放置用。
static func get_tile_parts(set_name: String, tile_name: String, variant: int) -> Array:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return []
    var rv := _resolve_variant(set_name, tile_name, variant)
    var sprite_name: String = rv[0]
    var vcol: int = rv[1]
    var base_cols: int = def.base_cols
    var source_id: int = TileSpritePreset.get_source_id(sprite_name)
    var out: Array = []
    for p in def.parts:
        var coords: Vector2i = p.coords + Vector2i(vcol * base_cols, 0)
        out.append({
            "source_id": source_id,
            "coords": coords,
            "dx": p.gcol - 1,
            "dy": p.grow - 1,
        })
    return out


# 变种信息（供 P3D 擦除用）：[sprite_name, atlas_coords]
static func get_tile_variant_info(set_name: String, tile_name: String, variant: int) -> Array:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return []
    var rv := _resolve_variant(set_name, tile_name, variant)
    var sprite_name: String = rv[0]
    var vcol: int = rv[1]
    var base_cols: int = def.base_cols
    var coords: Vector2i = def.parts[0].coords + Vector2i(vcol * base_cols, 0)
    return [sprite_name, coords]


# 注册/获取掩码后的 P3D 变体（基于素材生成独立 AtlasSource 加到共享 tileset）。
# 返回 {source_id, atlas_coords}
static func get_or_register_masked_p3d(sprite_name: String, atlas_coords: Vector2i,
        mask: BitMap) -> Dictionary:
    var mask_hash := _hash_mask(mask)
    var cache_key := sprite_name + "|" + str(atlas_coords) + "|" + mask_hash
    if _p3d_mask_variant_cache.has(cache_key):
        return _p3d_mask_variant_cache[cache_key]
    var masked_img := TileP3DEraseMask.build_masked_p3d_image(sprite_name, atlas_coords, mask)
    var src := TileSetAtlasSource.new()
    src.texture = ImageTexture.create_from_image(masked_img)
    src.texture_region_size = SysCfg.REGION_SIZE
    src.margins = SysCfg.TILE_MARGINS
    src.separation = SysCfg.TILE_SEPARATION
    src.create_tile(Vector2i(0, 0))
    var source_id: int = TileSpritePreset.tileset.add_source(src)
    var td: TileData = src.get_tile_data(Vector2i(0, 0), 0)
    td.texture_origin = Vector2i(-8, 8)
    var result := {"source_id": source_id, "atlas_coords": Vector2i(0, 0)}
    _p3d_mask_variant_cache[cache_key] = result
    return result


static func _hash_mask(bit_map: BitMap) -> String:
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


# 获取/注册 (set_name, tile_name, variant) 的 tile id
static func get_or_register_tile_id(set_name: String, tile_name: String, variant: int = 0) -> int:
    variant = clampi(variant, 0, maxi(0, get_tile_variant_count(set_name, tile_name) - 1))
    var key := set_name + "|" + tile_name + "|" + str(variant)
    if _tile_id_map.has(key):
        return _tile_id_map[key]
    var id := _tile_id_list.size()
    _tile_id_list.append([set_name, tile_name, variant])
    _tile_id_map[key] = id
    _tile_hash_cache[id] = get_tile_hash_by_id(id)
    return id


static func get_tile_id_info(id: int) -> Array:
    return _tile_id_list[id]


# 按 id 获取该 tile 所有子tile（含 source_id/coords/dx/dy）
static func get_tile_parts_by_id(tile_id: int) -> Array:
    if tile_id < 0 or tile_id >= _tile_id_list.size():
        return []
    var info: Array = _tile_id_list[tile_id]
    return get_tile_parts(info[0], info[1], info[2])


# 把 info [set_name, tile_name, variant] 转为第一个子tile 的 atlas_coords
static func get_tile_info_coords(info: Array) -> Vector2i:
    var parts := get_tile_parts(info[0], info[1], info[2])
    if parts.is_empty():
        return Vector2i(-1, -1)
    return parts[0].coords


# 按 id 计算形状哈希（用于擦除掩码邻居）
static func get_tile_hash_by_id(tile_id: int) -> String:
    var info: Array = _tile_id_list[tile_id]
    var rv := _resolve_variant(info[0], info[1], info[2])
    var def := get_tile_def(info[0], info[1])
    if def.is_empty():
        return ""
    var base_cols: int = def.base_cols
    var coords: Vector2i = def.parts[0].coords + Vector2i(rv[1] * base_cols, 0)
    return TileSpritePreset.get_tile_shape_hash(rv[0], coords)


static func get_tile_hash(tile_id: int) -> String:
    if _tile_hash_cache.has(tile_id):
        return _tile_hash_cache[tile_id]
    return get_tile_hash_by_id(tile_id)


# 获取素材图集图像（共享缓存）
static func get_sprite_atlas_image(sprite_name: String, is_p3d: bool) -> Image:
    return TileSpritePreset.get_atlas_image(sprite_name, is_p3d)


# 判断某 tile 是否具有 tag（匹配 tile_name 或 set_name）
static func has_tag(set_name: String, tile_name: String, tag: String) -> bool:
    return tile_name == tag or set_name == tag


static func has_match_rule(set_name: String) -> bool:
    return TileMatchRulePreset.get_(_we[set_name].tile_match_rule_name) != null


static func get_place_rule_names(set_name: String) -> Array:
    return _we[set_name].place_rule_names


# 默认 tile 名（match_rule 的 tiles_name (0,0) 位置）
static func get_default_tile_name(set_name: String) -> String:
    var rule := TileMatchRulePreset.get_(_we[set_name].tile_match_rule_name)
    if rule == null or rule.tiles_name.is_empty():
        return ""
    var first_row: Array = rule.tiles_name[0]
    if first_row.is_empty():
        return ""
    var cell = first_row[0]
    return cell[0] if cell is Array else str(cell)


# 该集合实际用于渲染的 TileSet（素材层共享）
static func tileset() -> TileSet:
    return TileSpritePreset.tileset


# Debug：把所有 tile 的所有变种保存到 Debug 目录（文件名含 集合名/tile名/变种/素材），便于检查
static func save_all_tiles_debug() -> void:
    for set_name in _tile_defs:
        var defs: Dictionary = _tile_defs[set_name]
        for tile_name in defs:
            var total := get_tile_variant_count(set_name, tile_name)
            for v in total:
                var vinfo: Array = get_tile_variant_info(set_name, tile_name, v)
                var sprite_name: String = vinfo[0]
                var coords: Vector2i = vinfo[1]
                var img := TileSpritePreset.get_region_image(sprite_name, coords, false)
                var file_name := "%s_%s_v%d_%s.png" % [set_name, tile_name, v, sprite_name]
                _save_debug_png(img, file_name)


static func _save_debug_png(image: Image, file_name: String) -> void:
    var debug_path: String = SysCfg.DEBUG_DIR + file_name
    DirAccess.make_dir_recursive_absolute(SysCfg.DEBUG_DIR)
    if image.save_png(debug_path) != OK:
        push_error("TileSetPreset: 保存调试图像失败: ", debug_path)
