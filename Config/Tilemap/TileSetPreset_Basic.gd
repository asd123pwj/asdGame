class_name TileSetPreset_Basic
extends ConfigBase

"""
name: String
layer: Enums.LayerType
tile_match_rule_name: String
sprites_name: Array[String]  （指向 TileSpritePreset 的各 name，作为该 tile 集合的变种）
place_rule_names: Array[String]

values 每条对应一个 TileSetPreset 实例：
    [name, layer, tile_match_rule_name, sprites_name, place_rule_names]
"""
var values: Array[Array] = [
    # 砖头：砖头 + Brown Brick 两个素材共同作为砖头的变种
    ["砖头", Enums.LayerType.MIDDLE, "BlockRule", ["砖头", "Brown Brick"]],

    ["水稻", Enums.LayerType.PLANT, "PlantRule", ["水稻"], ["test1", "test2"]],
    ["门", Enums.LayerType.FURNITURE, "DoorRule", ["门"]],
    ["透明玻璃", Enums.LayerType.MIDDLE, "BlockRule", ["透明玻璃"]],
    ["泥土", Enums.LayerType.MIDDLE, "BlockRule", ["泥土"]],
]

