class_name CollectLoot
extends BehaviorBase


func act(_char: Character, _config: Variant) -> Enums.Code:
    _char.attrs.init_attribute("Health")
    return Enums.Code.OK