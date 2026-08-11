class_name ScanInventory
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    _char.attrs.init_attribute("Health")
    return Enums.Code.OK