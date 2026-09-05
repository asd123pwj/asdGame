class_name MapSys
extends RefCounted

static var maps_parent_node: Node2D = Node2D.new()
# 世界层：layer_id -> MapLayer（每个 MapLayer 管理六个子层）
static var layers: Dictionary[int, MapLayer] = {}
# P3D 擦除掩码 shader（供 MapLayer 使用），通过 ShaderManager 按文件名访问
static var erase_shader: Shader = ShaderManager.get_shader("p3d_mask")


func _init() -> void:
    Sys.sys.add_child(maps_parent_node)

    # 创建一个世界层 layer 0
    var layer := MapLayer.new(0, maps_parent_node)
    layers[0] = layer
    # 循环1：记录待放置的 tile（只指定 source，具体 tile 由 build() 自动匹配）


    for i in range(1, 10):
        var j = -16
        # place(0, i+9, j+1, "白墙青瓦")
        place(0, i, j, "泥土")
        place(0, i+9, j, "砖头")
        place(0, i+18, j, "透明玻璃")
        place(0, i, j-1, "泥土")
        place(0, i+9, j-1, "砖头")
        place(0, i+18, j-1, "透明玻璃")
        place(0, i, j, "泥土")
        place(0, i+9, j, "砖头")
        place(0, i+18, j, "砖头")
        place(0, i, j-1, "砖头")
        place(0, i+9, j-1, "砖头")
        place(0, i+18, j-1, "砖头")
    
    place(0, 1, -15, "水稻")
    place(0, 2, -15, "水稻")
    place(0, 4, -15, "水稻")
    place(0, 5, -15, "门", "2")
    place(0, 6, -15, "门", "1")
    place(0, 7, -14, "门", "1")
    place(0, 7, -15, "门", "1")
    place(0, 8, -15, "水稻")
    place(0, 9, -14, "门", "1")
    place(0, 10, -14, "门", "1")
    place(0, 11, -14, "门", "1")
    place(0, 12, -14, "门", "1")
    place(0, 13, -14, "门", "1")
    place(0, 14, -14, "门", "1")
    place(0, 15, -14, "门", "1")

    for i in range(0, 4):
        for j in range(-6, -10, -1):
            # place(0, i, j, "P3D")
            place(0, i, j+5, "砖头")
            place(0, i+1, j+5+1, "透明玻璃")
            # place(0, i+5+1, j+5+1, "完整玻璃")
            # place(0, i+10+1, j+5+1, "完整玻璃-反")
    # 循环2：根据 map_content 放置 tile 和 P3D（增量 build：只更新有 _pending 的层）
    build()

    # Debug：输出所有 tile 到 Debug 目录（用时把 if false 改为 if true）
    if false:
        TileSetPreset.save_all_tiles_debug()
    # Debug：定位跨素材变种随机性问题（打印各素材的变种数）
    if false:
        TileSetPreset.debug_variant_counts("砖头", "M")
        TileSetPreset.debug_variant_counts("砖头", "FULL")


# 放置 tile/P3D：layer_id 世界层号；layer_type 用 tile 初始化时指定的层。
# 多格 tile：先判断锚点（左下角[1,1]）能否放置（位置+兼容），再检查组内其它位置是否有位置，全部通过才整组放置。
# tile_name 为空时使用默认占位 tile；指定 tile_name 时固定为该 tile。
static func place(layer_id: int, x: int, y: int,
        source_name: String = "", tile_name: String = "", variant: int = -1,
        force_space: bool = false, force_compatible: bool = false) -> void:
    var layer := layers[layer_id]

    # source 未指定时：沿用该位置当前已放置的 source；该位置为空则跳过
    var cur_source := source_name
    if cur_source.is_empty():
        cur_source = layer.get_source_at(x, y)
        if cur_source.is_empty():
            return

    var layer_type := TileSetPreset.get_(cur_source).layer

    var target_name := tile_name if not tile_name.is_empty() else TileSetPreset.get_default_tile_name(cur_source)
    if target_name.is_empty():
        push_error("MapSystem.place: source[", cur_source,
            "] 未配置匹配规则，无法确定占位 tile，请配置 tile_match_rule_name 或指定 tile_name")
        return
    if not TileSetPreset.has_tile_name(cur_source, target_name):
        push_error("MapSystem.place: source[", cur_source, "] 中找不到 tile 名称: ", target_name)
        return
    # 选变种：variant >= 0 用指定变种，否则随机（所有子tile 用同一变种）
    var vcount := TileSetPreset.get_tile_variant_count(cur_source, target_name)
    var sel_variant: int
    if variant >= 0:
        sel_variant = clampi(variant, 0, maxi(0, vcount - 1))
    else:
        sel_variant = randi() % maxi(1, vcount)
    var tile_id := TileSetPreset.get_or_register_tile_id(cur_source, target_name, sel_variant)
    var parts := TileSetPreset.get_tile_parts_by_id(tile_id)
    if parts.is_empty():
        return

    # 锚点 = 组内左下角 [1,1]（dx=0, dy=0）的子tile；找不到则用第一个
    # 找锚点 = 组内左下角 [1,1]（dx=0, dy=0）的子tile；找不到用第一个
    var anchor_idx := -1
    for i in parts.size():
        var p: Dictionary = parts[i]
        if p.dx == 0 and p.dy == 0:
            anchor_idx = i
            break
    if anchor_idx < 0:
        anchor_idx = 0
    var ax: int = x + parts[anchor_idx].dx
    var ay: int = y + parts[anchor_idx].dy

    # 锚点判断：先有位置（目标层及其不兼容层），再判断兼容（命名需求，source 未配置规则则直接通过）
    var place_rules := TileSetPreset.get_place_rule_names(cur_source)
    if not force_space and not MapPlaceRulePreset.check_can_place(layer_type, ax, ay,
            func(l: int, px: int, py: int) -> bool: return layer.has_tile(l, px, py)):
        if false:
            print("[MapSystem] ", cur_source, " 锚点(", ax, ",", ay, ") 无空间，不放置")
        return
    if not force_compatible and not MapPlaceRulePreset.check_compatible(place_rules, ax, ay,
            func(l: int, px: int, py: int, tag: String) -> bool:
                return layer.tile_has_tag(l, px, py, tag)):
        if false:
            print("[MapSystem] ", cur_source, " 锚点(", ax, ",", ay, ") 不兼容，不放置")
        return

    # 组内其它子tile 位置：只判断该位置是否有位置（直接查目标层，不判断兼容）
    if not force_space:
        for i in parts.size():
            if i == anchor_idx:
                continue
            var p: Dictionary = parts[i]
            var px: int = x + p.dx
            var py: int = y + p.dy
            if layer.has_tile(layer_type, px, py):
                return

    # 全部通过：整组放置（map_content 填整组各 tile，build 时按锚点展开）
    layer.place_group(layer_type, x, y, tile_id, not tile_name.is_empty())


# 增量 build：基于各 layer 的 _pending 是否有待放置内容，只更新有内容的层。
# 每层 build 完会清空自己的 _pending，故只有本轮新 place 过的层才会被真正更新，其余跳过。
static func build() -> void:
    for layer_id: int in layers:
        var layer := layers[layer_id]
        if layer.has_pending():
            layer.build()


static func map_layer_to_id(layer: int, layer_type: Enums.LayerType) -> int:
    return layer * Enums.LayerType.COUNT + layer_type

static func map_id_to_name(id: int) -> String:
    @warning_ignore("integer_division")
    var layer = id / Enums.LayerType.COUNT
    var layer_type = id % Enums.LayerType.COUNT
    return "Layer " + str(layer) + " " + Enums.StrLayerType[layer_type]
