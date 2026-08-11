class_name SayInjured
extends BehaviorBase


func act(_char: Character, _config: Variant) -> Enums.Code:
    

    var value_before = _char.attrs.get_("Health", Enums.ValueType.CUR, true)
    var value_cur = _char.attrs.get_("Health", Enums.ValueType.CUR)
    print(_char.name + "")

    return Enums.Code.OK