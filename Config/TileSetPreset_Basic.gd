class_name TileSetPreset_Basic
extends ConfigBase

"""
name: String
path: String
path_P3D: String
"""
var _prefix = "res://Material/Texture/"
var _values: Array[Array] = [
    ["Brown Brick", "BlockRule", "Block_Brick_Brown.png", "Block_Brick_Brown_P3D.png"],
    ["White Wall", "BlockRule", "Block_Brick.png"],
    ["白墙青瓦", "", "Block_Brick_WhiteWallGrayTile.png",],
    ["P3D", "BlockRule", "Tilemap_Placeholder.png", "Tilemap_Placeholder.png"],
    ["透明玻璃", "BlockRule", "Block_Transparent_Glass.png",],
    ["完整玻璃", "BlockRule", "完整玻璃.png"],
    ["完整玻璃-反", "BlockRule", "完整玻璃_P3D.png", "完整玻璃.png"],
]
var values: Array[Array] = []


func _init() -> void:
    for row in _values:
        var name_: String = row[0]
        var tile_match_rule_name: String = row[1]
        var file_name: String = row[2]
        var path_: String = _prefix + file_name
        var path_P3D: String
        if row.size() > 3:
            path_P3D = _prefix + row[3]
        else:
            # 无第三列时，用第二列文件名（去扩展名）+ _P3D 后缀
            path_P3D = _prefix + file_name.get_basename() + "_P3D." + file_name.get_extension()
        values.append([name_, tile_match_rule_name, path_, path_P3D])
    super._init()