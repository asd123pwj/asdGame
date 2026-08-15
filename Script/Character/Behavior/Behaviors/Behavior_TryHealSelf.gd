class_name Behavior_TryHealSelf
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    for item: Character in _char.inventories.get_Backpack():
        if item.statuses.check_satisfied("Healable"):
            MsgHubChar.send_status_detected(_char, "Detect=>Edible", item)
    return Enums.Code.OK
    