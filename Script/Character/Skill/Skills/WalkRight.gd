class_name WalkRight
extends RefCounted

# ----- Config -----
var _me: Character

func _init(char_: Character):
    _me = char_

static func act(_char: Character, _config: Array) -> void:
    _char.attrs.init_attribute("Health")