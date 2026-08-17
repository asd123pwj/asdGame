class_name Interaction_AddBuff
extends InteractionBase



func interact(user: Character, _none) -> Enums.Code:
    user.attrs.add_buff(config)
    return Enums.Code.OK
    