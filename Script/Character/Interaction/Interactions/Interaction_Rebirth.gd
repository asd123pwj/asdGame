class_name Interaction_Rebirth
extends InteractionBase

func interact(me: Character, _target) -> Array:
    me.attrs.init_attribute("Health", Enums.ValueType.CUR)
    me.attrs.consume_buffs("Health", Enums.ValueType.CUR)
    return [Enums.Code.OK]