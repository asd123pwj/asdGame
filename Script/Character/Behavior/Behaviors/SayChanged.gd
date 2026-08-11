class_name SayChanged
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    var value_before = _char.attrs.get_(_config[0], Enums.ValueType.CUR, true)
    var value_cur = _char.attrs.get_(_config[0], Enums.ValueType.CUR)
    var changed_by_how = _char.attrs.get_changed_by_how(_config[0])
    var changed_by_who = _char.attrs.get_changed_by_who(_config[0])
    print("在" + changed_by_who.name + "的" + changed_by_how + "影响下，" + _char.name + "的" + _config[0] + "从" + str(value_before) + "变为" + str(value_cur) + "。")

    return Enums.Code.OK