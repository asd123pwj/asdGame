class_name TileSpritePreset_Basic
extends ConfigBase

"""
name: String
region_size: int
path: String
values 每条对应一个 TileSpritePreset 实例（单个图片素材）：
    [name, region_size, path]
P3D 素材按同目录下 "xxx_P3D.png" 是否存在自动加载。
"""
var _prefix = "res://Material/Texture/Tile/"
var _values: Array[Array] = [
    ["砖头", 48, "Block_Brick.png"],
    ["Brown Brick", 48, "Block_Brick_Brown.png"],

    ["水稻", 32, "Plant_Rice.png"],
    ["门", 32, "Furniture_Door.png"],
    ["透明玻璃", 48, "Block_Transparent_Glass.png"],
    ["泥土", 48, "Block_Soil.png"],
]
var values: Array[Array] = []


func _init() -> void:
    for row in _values:
        var name_: String = row[0]
        var region_size: int = row[1]
        var path_: String = _prefix + row[2]
        values.append([name_, region_size, path_])
    super._init()
