class_name TileSetPreset_Basic
extends ConfigBase

"""
name: String
path: String（材质/纹理路径）
"""
var _prefix = "res://Material/Texture/"
var values: Array[Array] = [
    ["Brown Brick", _prefix + "Block_Brick_Brown.png"],
    ["White Wall", _prefix + "Block_Brick.png"],
    ["白墙青瓦", _prefix + "Block_Brick_WhiteWallGrayTile.png"],
]
