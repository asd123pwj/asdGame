class_name Interaction_AddBuff
extends InteractionBase



func interact(user: Character, _none) -> Array:
    return [user.attrs.add_buff(config)]
    