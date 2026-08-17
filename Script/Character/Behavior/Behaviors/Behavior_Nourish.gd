class_name Behavior_Nourish
extends BehaviorBase


func act(me: Character, _config: Array) -> Enums.Code:
    me.attrs.add_buff("Nourish")
    return Enums.Code.OK
    