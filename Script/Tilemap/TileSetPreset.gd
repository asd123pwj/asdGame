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
# tile 定义：set_name -> tile_name -> {base_cols, parts:[{dx,dy,coords,size}]}
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
    var rule := TileNameRulePreset.get_(_we[set_name].tile_match_rule_name)
    var defs: Dictionary = {}
    if rule != null and not rule.tiles_name.is_empty():
        _parse_tiles_name(set_name, rule.tiles_name, defs)
    _tile_defs[set_name] = defs


static func _parse_tiles_name(_set_name: String, tiles_name: Array, defs: Dictionary) -> void:
    # 第一遍：收集每个名称的所有出现 (col, row, size)
    var occurrences: Dictionary = {}  # tile_name -> [{col,row,size}]
    for row in tiles_name.size():
        var row_cells: Array = tiles_name[row]
        for col in row_cells.size():
            var cell = row_cells[col]
            var tile_name: String
            var size := SysCfg.REGION_SIZE
            if cell is Array:
                var cell_arr: Array = cell
                tile_name = str(cell_arr[0])
                if cell_arr.size() > 1 and cell_arr[1] is Array:
                    var size_arr: Array = cell_arr[1]
                    if size_arr.size() >= 2:
                        size = Vector2i(size_arr[1], size_arr[0])  # [H,W] -> (w,h)
            else:
                tile_name = str(cell)
            if tile_name.is_empty():
                continue
            if not occurrences.has(tile_name):
                occurrences[tile_name] = []
            var occ_list: Array = occurrences[tile_name]
            occ_list.append({"col": col, "row": row, "size": size})
    # 第二遍：同名 tile 的所有出现合成一个多格组；锚点 = 最左下角（min_col, max_row）。
    # 组内位置 dx/dy（锚点为 1,1）；变种 = 组整体水平偏移 base_cols 列。
    for tile_name in occurrences:
        var occs: Array = occurrences[tile_name]
        var min_col := 0x7FFFFFFF
        var max_row := -0x7FFFFFFF
        var max_col := -0x7FFFFFFF
        for o in occs:
            min_col = mini(min_col, o.col)
            max_row = maxi(max_row, o.row)
            max_col = maxi(max_col, o.col)
        var base_cols := max_col - min_col + 1
        var parts: Array = []
        for o in occs:
            parts.append({
                "dx": o.col - min_col,   # 向右为正
                "dy": max_row - o.row,   # 向上为正
                "coords": Vector2i(o.col, o.row),
                "size": o.size,
            })
        # variants 懒展开：每组（完整多格）作为一个列表元素，随机时从整个列表选一组
        defs[tile_name] = {"base_cols": base_cols, "parts": parts, "variants": [], "variants_ready": false}


# tile_name 是否存在（解析自 match_rule 的 tiles_name）
static func has_tile_name(set_name: String, tile_name: String) -> bool:
    var defs: Dictionary = _tile_defs.get(set_name, {})
    return defs.has(tile_name)


static func get_tile_def(set_name: String, tile_name: String) -> Dictionary:
    var defs: Dictionary = _tile_defs.get(set_name, {})
    # 懒重建：若首次注册时 match_rule 尚未就绪导致 defs 为空，且现在规则已可用则重建
    if defs.is_empty() and TileNameRulePreset.get_(_we[set_name].tile_match_rule_name) != null:
        _build_tile_defs(set_name)
        defs = _tile_defs.get(set_name, {})
    var d = defs.get(tile_name)
    return d if d is Dictionary else {}


# 某素材下该 tile_name 的有效变种列（索引）。变种数由 TileSpritePreset._to_48_atlas 基于图像内容计算，
# TileSetPreset 只关心"该素材该 tile 有几个变种"，不关心具体内容。
static func _sprite_variant_cols(_set_name: String, tile_name: String, sprite_name: String) -> Array:
    var count: int = TileSpritePreset.get_group_variant_count(sprite_name, tile_name)
    if count <= 0:
        return []
    var vcols: Array = []
    for v in count:
        vcols.append(v)
    return vcols


# 懒展开该 tile 的变种列表：遍历所有素材(PNG)，对每个 PNG 内每个有效变种，生成一个完整多格组元素。
# 每组作为一个列表元素，随机时从整个列表选一组（不关心来自哪个 PNG）。
static func _ensure_variants(set_name: String, tile_name: String, def: Dictionary) -> void:
    if def.variants_ready:
        return
    var base_cols: int = def.base_cols
    var variants: Array = []
    for sp in _we[set_name].sprites_name:
        var vcols := _sprite_variant_cols(set_name, tile_name, sp)
        for vcol in vcols:
            # 该变种的完整多格组 parts（coords 已含列偏移）
            var vparts: Array = []
            for p in def.parts:
                vparts.append({
                    "dx": p.dx,
                    "dy": p.dy,
                    "coords": p.coords + Vector2i(vcol * base_cols, 0),
                    "size": p.size,
                })
            variants.append({"sprite": sp, "vcol": vcol, "parts": vparts})
    def.variants = variants
    # 只有展开出至少一个变种才标记就绪；为空说明素材尚未就绪，允许下次重试
    if not variants.is_empty():
        def.variants_ready = true


# 该 tile_name 的总变种数（= 所有 PNG 内变种之和，扁平列表长度）
static func get_tile_variant_count(set_name: String, tile_name: String) -> int:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return 0
    _ensure_variants(set_name, tile_name, def)
    var variants: Array = def.variants
    return variants.size()


# Debug：打印各素材下某 tile 的变种数（定位跨素材随机性问题）
static func debug_variant_counts(set_name: String, tile_name: String) -> void:
    for sp in _we[set_name].sprites_name:
        var vcols := _sprite_variant_cols(set_name, tile_name, sp)
        print("[TileSetPreset] ", set_name, "/", tile_name, " sprite=", sp,
            " cols=", TileSpritePreset.get_column_count(sp),
            " vcols=", vcols)


# 变种索引 → 变种元素 {sprite, vcol}（直接索引扁平变种列表，跨 PNG 与 PNG 内变种同权）
static func _resolve_variant(set_name: String, tile_name: String, variant: int) -> Dictionary:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return {}
    _ensure_variants(set_name, tile_name, def)
    var variants: Array = def.variants
    if variants.is_empty():
        return {}
    var vi := clampi(variant, 0, variants.size() - 1)
    return variants[vi]


# 获取某 tile 变种的所有子tile（含 source_id）。供渲染放置用。
static func get_tile_parts(set_name: String, tile_name: String, variant: int) -> Array:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return []
    var rv := _resolve_variant(set_name, tile_name, variant)
    if rv.is_empty():
        return []
    var sprite_name: String = rv.sprite
    var vparts: Array = rv.parts
    var source_id: int = TileSpritePreset.get_source_id(sprite_name)
    var out: Array = []
    for p in vparts:
        out.append({
            "source_id": source_id,
            "coords": p.coords,
            "dx": p.dx,
            "dy": p.dy,
        })
    return out


# 变种信息（供 P3D 擦除用）：[sprite_name, atlas_coords]
static func get_tile_variant_info(set_name: String, tile_name: String, variant: int) -> Array:
    var def := get_tile_def(set_name, tile_name)
    if def.is_empty():
        return []
    var rv := _resolve_variant(set_name, tile_name, variant)
    if rv.is_empty():
        return []
    var vparts: Array = rv.parts
    if vparts.is_empty():
        return []
    return [rv.sprite, vparts[0].coords]


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


# 按 tile_id 反查其所属集合名（source_name），供"使用当前位置已放置的 source"场景
static func get_set_name_by_id(tile_id: int) -> String:
    if tile_id < 0 or tile_id >= _tile_id_list.size():
        return ""
    return _tile_id_list[tile_id][0]


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
    if rv.is_empty():
        return ""
    var vparts: Array = rv.parts
    if vparts.is_empty():
        return ""
    return TileSpritePreset.get_tile_shape_hash(rv.sprite, vparts[0].coords)


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
    var rule := TileNameRulePreset.get_(_we[set_name].tile_match_rule_name)
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


# Debug：把所有 tile 的所有变种保存到 Debug 目录。
# 对多格 tile，把整组按 dx/dy 拼成一张完整图保存（文件名含 集合/tile/变种/素材）。
static func save_all_tiles_debug() -> void:
    for set_name in _tile_defs:
        var defs: Dictionary = _tile_defs[set_name]
        for tile_name in defs:
            var total := get_tile_variant_count(set_name, tile_name)
            for v in total:
                var parts := get_tile_parts(set_name, tile_name, v)
                if parts.is_empty():
                    continue
                var sprite_name: String = _resolve_variant(set_name, tile_name, v).sprite
                # 确定整组画布：dx/dy 范围
                var max_dx := 0
                var max_dy := 0
                for p in parts:
                    max_dx = maxi(max_dx, p.dx)
                    max_dy = maxi(max_dy, p.dy)
                var img := Image.create(
                    (max_dx + 1) * SysCfg.REGION_SIZE.x,
                    (max_dy + 1) * SysCfg.REGION_SIZE.y,
                    false, Image.FORMAT_RGBA8)
                img.fill(Color(0, 0, 0, 0))
                for p in parts:
                    var cell := TileSpritePreset.get_region_image(sprite_name, p.coords, false)
                    img.blit_rect(cell, Rect2i(0, 0, cell.get_width(), cell.get_height()),
                        Vector2i(p.dx * SysCfg.REGION_SIZE.x,
                            (max_dy - p.dy) * SysCfg.REGION_SIZE.y))
                    # 同时保存该位置的单个格子素材，命名含位置（锚点左下为 1,1）
                    var pos_file := "%s_%s_v%d_%d,%d_%s.png" % [
                        set_name, tile_name, v, p.dx + 1, p.dy + 1, sprite_name]
                    _save_debug_png(cell, pos_file)
                var file_name := "%s_%s_v%d_%s.png" % [set_name, tile_name, v, sprite_name]
                _save_debug_png(img, file_name)


static func _save_debug_png(image: Image, file_name: String) -> void:
    var debug_path: String = SysCfg.DEBUG_DIR + file_name
    DirAccess.make_dir_recursive_absolute(SysCfg.DEBUG_DIR)
    if image.save_png(debug_path) != OK:
        push_error("TileSetPreset: 保存调试图像失败: ", debug_path)
