class_name CollectLoot
extends RefCounted


static func act(_char: Character, _config: Array) -> void:
    _char.attrs.init_attribute("Health")