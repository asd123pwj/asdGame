class_name Interaction_TryHealSelf
extends InteractionBase

func interact(me: Character, _target: Character) -> Enums.Code:
    for item: Character in me.inventories.get_Backpack():
        if item.statuses.check_satisfied("Healable"):
            MsgHubChar.send_status_detected(me, "Detect=>Edible", item)
    return Enums.Code.OK