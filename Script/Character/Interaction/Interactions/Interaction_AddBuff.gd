class_name Interaction_AddBuff
extends InteractionBase



func interact(user: Character, _none, buff_name: String) -> Enums.Code:
    user.attrs.add_buff(buff_name)
    return Enums.Code.OK
    