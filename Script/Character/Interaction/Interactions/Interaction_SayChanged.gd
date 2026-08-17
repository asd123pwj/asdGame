class_name Interaction_SayChanged
extends InteractionBase


func interact(me: Character, _target) -> Enums.Code:
    if typeof(_target) == TYPE_STRING:
        var attr_name = _target
        var value_before = me.attrs.get_(attr_name, Enums.ValueType.CUR, true)
        var value_cur = me.attrs.get_(attr_name, Enums.ValueType.CUR)
        var changed_by_how = me.attrs.get_changed_by_how(attr_name)
        var changed_by_who = me.attrs.get_changed_by_who(attr_name)
        print("在" + changed_by_who.name + "的" + changed_by_how + "影响下，" + me.name + "的" + attr_name + "从" + str(value_before) + "变为" + str(value_cur) + "。")

    return Enums.Code.OK