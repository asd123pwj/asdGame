class_name Rebirth
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    _char.attrs.init_attribute("Health")
    return Enums.Code.OK