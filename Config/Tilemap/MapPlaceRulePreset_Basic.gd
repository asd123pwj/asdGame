class_name MapPlaceRulePreset_Basic
extends ConfigBase

"""
name
values 每条对应一个 MapPlaceRulePreset 实例（单个命名放置需求）：
    [name, offset_x, offset_y, layer, tag, must_have]
    offset_x/offset_y : 检索位置相对当前格的偏移（逻辑坐标 y 向上为正）
    layer             : Enums.LayerType（要检查的层）
    tag               : 匹配该格 tile 的 tile_name 或 source_name
    must_have         : true=必须有该 tag；false=必须没有
"""
var values: Array[Array] = [
    # test1：当前位置左边格(-1,0) 的 PLANT 层不应有水稻（不能相邻堆叠）
    ["test1", -1, 0, Enums.LayerType.PLANT, "水稻", false],
    # test2：当前位置下方格(0,-1) 的 MIDDLE 层必须有泥土（不能悬空，需种在泥土上）
    ["test2", 0, -1, Enums.LayerType.MIDDLE, "泥土", true],
    # test3：当前格(0,0) 的 MIDDLE 层不应有泥土（不能覆盖地面物）
    ["test3", 0, 0, Enums.LayerType.MIDDLE, "泥土", false],
]
