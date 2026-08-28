class_name TileSetPreset_Basic
extends ConfigBase

"""
name: String
path: String
path_P3D: String
"""
var _prefix = "res://Material/Texture/Tile/"
var _values: Array[Array] = [
    ["Brown Brick", Enums.LayerType.MIDDLE, "BlockRule", "Block_Brick_Brown.png"],
    ["White Wall", Enums.LayerType.MIDDLE, "BlockRule", "Block_Brick.png"],
    ["白墙青瓦", Enums.LayerType.MIDDLE, "", "Block_Brick_WhiteWallGrayTile.png",],
    # ["P3D", Enums.LayerType.MIDDLE, "BlockRule", "Tilemap_Placeholder.png", "Tilemap_Placeholder.png"],
    ["透明玻璃", Enums.LayerType.MIDDLE, "BlockRule", "Block_Transparent_Glass.png",],
    ["泥土", Enums.LayerType.MIDDLE, "BlockRule", "Block_Soil.png",],
    # ["完整玻璃", Enums.LayerType.MIDDLE, "BlockRule", "完整玻璃.png"],
    # ["完整玻璃-反", Enums.LayerType.MIDDLE, "BlockRule", "完整玻璃_P3D.png", "完整玻璃.png"],
    ["水稻", Enums.LayerType.PLANT, "PlantRule", "Plant_Rice.png",],
]
var values: Array[Array] = []


func _init() -> void:
    for row in _values:
        var name_: String = row[0]
        var layer: Enums.LayerType = row[1]
        var tile_match_rule_name: String = row[2]
        var file_name: String = row[3]
        var path_: String = _prefix + file_name
        # var path_P3D: String
        # if row.size() > 3:
        #     path_P3D = _prefix + row[3]
        # else:
        #     # 无第三列时，用第二列文件名（去扩展名）+ _P3D 后缀
        #     path_P3D = _prefix + file_name.get_basename() + "_P3D." + file_name.get_extension()
        values.append([name_, layer, tile_match_rule_name, path_])
    super._init()