class_name ScanInventory
extends RefCounted


static func act(_char: Character, _config: Array) -> void:
    _char.attrs.init_attribute("Health")