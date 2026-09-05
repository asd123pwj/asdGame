class_name TileSpritePreset
extends PresetRegister

# 单个图片素材：只负责 source 加载、region 读取、碰撞体、hash、图集尺寸等素材相关计算。
# 不关心 tile 名称（tile_name → 行列 的解析由 TileSetPreset 用 match_rule 完成）。
# P3D 素材按同目录下 "xxx_P3D" 后缀文件是否存在来决定是否加载。

var name: String
var match_rule_name: String
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
# 素材内每组 tile 的变种数：sprite_name -> tile_name -> count（供 TileSetPreset 读取）
static var _variant_count_by_tile: Dictionary = {}

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


func _init(name: String, match_rule_name: String, path: String) -> void:
    _we[name] = self
    self.name = name
    self.match_rule_name = match_rule_name
    self.path = path
    # P3D：同目录下是否存在 "_P3D" 后缀文件，有则加载，无则忽略
    var p3d_path := path.get_basename() + "_P3D." + path.get_extension()
    if ResourceLoader.exists(p3d_path):
        path_P3D = p3d_path
        has_p3d = true

    var cell_sizes := TileNameRulePreset.get_cell_sizes(match_rule_name)
    var tiles_name: Array = TileNameRulePreset.get_(match_rule_name).tiles_name
    source = _create_source(path, cell_sizes, tiles_name, name)
    source_id = tileset.add_source(source)
    _create_tiles(source, true)

    if has_p3d:
        # P3D 用独立 key 存储变种数/掩码，避免覆盖普通素材（P3D 图内容可能不同）
        source_P3D = _create_source(path_P3D, cell_sizes, tiles_name, name + "_P3D")
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


# 素材内某 tile 的变种数（由 _to_48_atlas 基于图像内容计算）。供 TileSetPreset 集合内随机用。
static func get_group_variant_count(sprite_name: String, tile_name: String) -> int:
    var per_sprite: Dictionary = _variant_count_by_tile.get(sprite_name, {})
    return per_sprite.get(tile_name, 0)


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


# 创建 source（仅配置，不含瓦片）。素材图集紧密排列不同尺寸格子，统一重排成规整 48x48。
# 同时生成剪裁掩码图（标记每个格子的理论裁切区域，含变种）供核对。
static func _create_source(path: String, cell_sizes: Array[Array], tiles_name: Array, sprite_name: String) -> TileSetAtlasSource:
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("TileSpritePreset: 无法加载贴图: ", path)
        return TileSetAtlasSource.new()
    var img: Image = texture.get_image()
    # 任何素材都生成掩码并重排（全48时重排结果与原图一致）
    img = _to_48_atlas(img, cell_sizes, tiles_name, sprite_name)
    if false:
        _save_debug_png(img, path.get_file().get_basename() + "_48.png")
    var source := TileSetAtlasSource.new()
    source.texture = ImageTexture.create_from_image(img)
    source.texture_region_size = SysCfg.REGION_SIZE
    source.margins = SysCfg.TILE_MARGINS
    source.separation = SysCfg.TILE_SEPARATION
    return source


# 是否需要重排：cell_sizes 非空且存在非 48x48 的格子
static func _need_reflow(cell_sizes: Array[Array]) -> bool:
    if cell_sizes.is_empty():
        return false
    for row_sizes in cell_sizes:
        for size in row_sizes:
            if size != SysCfg.REGION_SIZE:
                return true
    return false


# 把"紧密排列不同尺寸 + 变种"的素材图集重排成规整 48x48 网格。
# 1) 从 cell_sizes/tiles_name 确定本组布局（行高=行最大高，行内紧密排列，底部对齐）
# 2) 根据原图内容检测每组变种数（组水平偏移组宽处非空即有一份变种）
# 3) 生成掩码图（标记所有格子本组+变种区域）
# 4) 重排所有格子到规整 48 网格（本组 + 变种列偏移）
static func _to_48_atlas(image: Image, cell_sizes: Array[Array], tiles_name: Array, sprite_name: String) -> Image:
    var rows := cell_sizes.size()
    # 解析每格名称归属（tiles_name 行列结构同 cell_sizes）
    var names: Array = []
    for r in rows:
        var rn: Array = []
        if r < tiles_name.size():
            var row_cells: Array = tiles_name[r]
            for cell in row_cells:
                if cell is Array and not (cell as Array).is_empty():
                    rn.append(str((cell as Array)[0]))
                else:
                    rn.append(str(cell))
        names.append(rn)
    # 本组紧密排列布局
    var row_heights: Array = []
    for r in rows:
        var max_h := 0
        for size in cell_sizes[r]:
            max_h = maxi(max_h, size.y)
        row_heights.append(maxi(max_h, 1))
    # 每行格子：name, base_x（行内 x）, size, gcol（本组内列索引）
    var row_cells_data: Array = []  # [r] -> [{name, base_x, size, gcol}]
    var src_y := 0
    for r in rows:
        var rh: int = row_heights[r]
        var sx := 0
        var cells: Array = []
        for c in cell_sizes[r].size():
            var size: Vector2i = cell_sizes[r][c]
            cells.append({"name": names[r][c], "base_x": sx, "size": size, "gcol": c})
            sx += size.x
        row_cells_data.append({"src_y": src_y, "rh": rh, "roww": sx, "cells": cells})
        src_y += rh
    # 每组本组宽度/列数 = 该组在涉及行中的同名格子宽度和/数量（跨行取最大）
    var group_width: Dictionary = {}
    var group_cols: Dictionary = {}
    for r in rows:
        # 按名称统计该行各组的宽度和数量
        var row_name_w: Dictionary = {}
        var row_name_cnt: Dictionary = {}
        for c in row_cells_data[r].cells:
            var name: String = c.name
            row_name_w[name] = row_name_w.get(name, 0) + c.size.x
            row_name_cnt[name] = row_name_cnt.get(name, 0) + 1
        for name in row_name_w:
            group_width[name] = maxi(group_width.get(name, 0), row_name_w[name])
            group_cols[name] = maxi(group_cols.get(name, 0), row_name_cnt[name])
    # 检测每组变种数 = 原图该行内容宽 / 该行 tiles_name 总宽（基于图像实际内容，不依赖形状相似度）。
    # 同一行的所有 tile 共享变种数（变种 = 整行内容的水平副本）。
    var group_variant_count: Dictionary = {}
    var row_vcount: Dictionary = {}
    for r in rows:
        var y0: int = row_cells_data[r].src_y
        var y1: int = y0 + row_cells_data[r].rh
        var content_w: int = _row_content_width(image, y0, y1)
        var self_w: int = row_cells_data[r].roww
        if self_w > 0:
            row_vcount[r] = maxi(1, ceili(float(content_w) / float(self_w)))
        else:
            row_vcount[r] = 1
    for name in group_width:
        var vcount := 1
        for r in rows:
            var has_name := false
            for c in row_cells_data[r].cells:
                if c.name == name:
                    has_name = true
                    break
            if has_name:
                vcount = maxi(vcount, row_vcount[r])
        group_variant_count[name] = vcount
    # 存储该素材每组 tile 的变种数，供 TileSetPreset 在集合内统一随机使用
    var per_sprite: Dictionary = _variant_count_by_tile.get(sprite_name, {})
    for name in group_variant_count:
        per_sprite[name] = group_variant_count[name]
    _variant_count_by_tile[sprite_name] = per_sprite
    # 规整网格列数 = max(本组列数 * 变种数)
    var cols := 0
    for name in group_cols:
        cols = maxi(cols, group_cols[name] * group_variant_count[name])
    var out := Image.create(
        cols * SysCfg.REGION_SIZE.x, rows * SysCfg.REGION_SIZE.y,
        false, image.get_format())
    out.fill(Color(0, 0, 0, 0))
    # 生成剪裁掩码并保存（任何素材都生成）
    var mask := _build_mask(row_cells_data, group_width, group_variant_count)
    _save_debug_png(mask, sprite_name + "_CropMask.png")
    # 全48规整素材无需重排，直接返回原图
    if not _need_reflow(cell_sizes):
        return image
    var img_w: int = image.get_width()
    var img_h: int = image.get_height()
    for r in rows:
        for c in row_cells_data[r].cells:
            var name: String = c.name
            var size: Vector2i = c.size
            var cy_src_y: int = row_cells_data[r].src_y
            var rh: int = row_cells_data[r].rh
            var base_y: int = cy_src_y + (rh - size.y)  # 底部对齐
            var col_count: int = group_cols[name]
            for v in group_variant_count[name]:
                var src_x: int = c.base_x + group_width[name] * v
                if src_x + size.x > img_w or base_y + size.y > img_h:
                    continue
                var src_rect := Rect2i(src_x, base_y, size.x, size.y)
                # 目标列 = 本组内列 gcol + v * 本组列数
                var gcol: int = c.gcol
                var dst := Vector2i(
                    (gcol + v * col_count) * SysCfg.REGION_SIZE.x,
                    r * SysCfg.REGION_SIZE.y + (SysCfg.REGION_SIZE.y - size.y))
                out.blit_rect(image, src_rect, dst)
    return out


# 扫描原图某 y 范围，返回最右侧非空像素的 x+1（该行内容宽度）
static func _row_content_width(image: Image, y0: int, y1: int) -> int:
    var img_w: int = image.get_width()
    var max_x := 0
    for y in range(y0, mini(y1, image.get_height())):
        for x in range(img_w - 1, -1, -1):
            if image.get_pixel(x, y).a > 0:
                if x + 1 > max_x:
                    max_x = x + 1
                break
    return max_x


# 生成剪裁掩码图：标记所有格子（本组 + 变种）的源区域。
# 内部按 tile 名着色（相同 tile 的所有变种同色）；方框按变种索引着色（不同变种方框不同色）。
static func _build_mask(row_cells_data: Array, group_width: Dictionary,
        group_variant_count: Dictionary) -> Image:
    var total_h := 0
    for r in row_cells_data.size():
        total_h += row_cells_data[r].rh
    var max_w := 0
    for r in row_cells_data.size():
        for c in row_cells_data[r].cells:
            var name: String = c.name
            var last_v: int = maxi(0, group_variant_count[name] - 1)
            max_w = maxi(max_w, c.base_x + group_width[name] * last_v + c.size.x)
    var mask := Image.create(max_w, total_h, false, Image.FORMAT_RGBA8)
    mask.fill(Color(0, 0, 0, 0))
    var colors: Array = [
        Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1), Color(1, 1, 0),
        Color(1, 0, 1), Color(0, 1, 1), Color(1, 0.5, 0), Color(0.5, 0, 1),
        Color(0.2, 0.8, 0.5), Color(0.8, 0.2, 0.5),
    ]
    # 方框颜色按变种索引分配（不同变种不同色，跨 tile 同变种索引同色）
    var outline_colors: Array = [
        Color(1, 1, 1), Color(0, 0, 0), Color(1, 1, 0), Color(0, 1, 1),
        Color(1, 0, 1), Color(0.5, 0.5, 0), Color(0, 0.5, 0.5), Color(0.5, 0, 0.5),
    ]
    # 为每个 tile 名分配固定填充颜色（相同 tile 的不同变种同色）
    var name_color: Dictionary = {}
    var ci := 0
    for r in row_cells_data.size():
        for c in row_cells_data[r].cells:
            if not name_color.has(c.name):
                name_color[c.name] = colors[ci % colors.size()]
                ci += 1
    for r in row_cells_data.size():
        var rh: int = row_cells_data[r].rh
        for c in row_cells_data[r].cells:
            var size: Vector2i = c.size
            var base_y: int = row_cells_data[r].src_y + (rh - size.y)
            var col: Color = name_color[c.name]
            for v in group_variant_count[c.name]:
                var src_x: int = c.base_x + group_width[c.name] * v
                _mask_fill(mask, src_x, base_y, size.x, size.y, col)
                var ocol: Color = outline_colors[v % outline_colors.size()]
                _mask_outline(mask, src_x, base_y, size.x, size.y, ocol)
    return mask


static func _mask_fill(mask: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
    for py in range(y, y + h):
        for px in range(x, x + w):
            if px >= 0 and px < mask.get_width() and py >= 0 and py < mask.get_height():
                mask.set_pixel(px, py, color)


# 画格子白色方框（1px 边框）
static func _mask_outline(mask: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
    for px in range(x, x + w):
        if px >= 0 and px < mask.get_width() and y >= 0 and y < mask.get_height():
            mask.set_pixel(px, y, color)
            if y + h - 1 < mask.get_height():
                mask.set_pixel(px, y + h - 1, color)
    for py in range(y, y + h):
        if py >= 0 and py < mask.get_height() and x >= 0 and x < mask.get_width():
            mask.set_pixel(x, py, color)
            if x + w - 1 < mask.get_width():
                mask.set_pixel(x + w - 1, py, color)


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
