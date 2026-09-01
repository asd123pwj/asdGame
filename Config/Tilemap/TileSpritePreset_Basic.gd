class_name TileSpritePreset_Basic
extends ConfigBase

"""
name: String
match_rule_name: String  （指示该素材每行切法，由 TileMatchRulePreset 的 tiles_name 行首高度决定，32/48）
path: String
values 每条对应一个 TileSpritePreset 实例（单个图片素材）：
    [name, match_rule_name, path]
P3D 素材按同目录下 "xxx_P3D.png" 是否存在自动加载。
"""
var _prefix = "res://Material/Texture/Tile/"
var _values: Array[Array] = [
    ["砖头", "BlockRule", "Block_Brick.png"],
    ["Brown Brick", "BlockRule", "Block_Brick_Brown.png"],

    ["水稻", "PlantRule", "Plant_Rice.png"],
    ["门", "DoorRule", "Furniture_Door.png"],
    ["透明玻璃", "BlockRule", "Block_Transparent_Glass.png"],
    ["泥土", "BlockRule", "Block_Soil.png"],
]
var values: Array[Array] = []


func _init() -> void:
    for row in _values:
        var name_: String = row[0]
        var match_rule_name: String = row[1]
        var path_: String = _prefix + row[2]
        values.append([name_, match_rule_name, path_])
    super._init()
