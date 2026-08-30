class_name TileSetPreset_Basic
extends ConfigBase

"""
name: String
path: String
"""
var _prefix = "res://Material/Texture/Tile/"
var _values: Array[Array] = [
    ["砖头", Enums.LayerType.MIDDLE, 48, "BlockRule", "Block_Brick.png"],
    ["水稻", Enums.LayerType.PLANT, 32, "PlantRule", "Plant_Rice.png", ["test1", "test2"]],
    ["门", Enums.LayerType.FURNITURE, 32, "DoorRule", "Furniture_Door.png"],
    # ["Brown Brick", Enums.LayerType.MIDDLE, 48, "BlockRule", "Block_Brick_Brown.png"],
    # ["白墙青瓦", Enums.LayerType.MIDDLE, 48, "", "Block_Brick_WhiteWallGrayTile.png",],
    ["透明玻璃", Enums.LayerType.MIDDLE, 48, "BlockRule", "Block_Transparent_Glass.png",],
    ["泥土", Enums.LayerType.MIDDLE, 48, "BlockRule", "Block_Soil.png",],
    # ["完整玻璃", Enums.LayerType.MIDDLE, 48, "BlockRule", "完整玻璃.png"]
]
var values: Array[Array] = []


func _init() -> void:
    for row in _values:
        var name_: String = row[0]
        var layer: Enums.LayerType = row[1]
        var region_size: int = row[2]
        var tile_match_rule_name: String = row[3]
        var path_: String = _prefix + row[4]
        var place_rules: Array = row[5] if row.size() > 5 else []
        values.append([name_, layer, region_size, tile_match_rule_name, path_, place_rules])
    super._init()