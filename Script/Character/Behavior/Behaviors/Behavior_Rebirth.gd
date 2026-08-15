class_name Behavior_Rebirth
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    _char.attrs.init_attribute("Health", Enums.ValueType.CUR, CLASS_NAME)
    return Enums.Code.OK