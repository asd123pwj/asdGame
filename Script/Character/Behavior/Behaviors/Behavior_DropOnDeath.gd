class_name Behavior_DropOnDeath
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    for race in _char.inventories.get_DeadDrop():
        # CharSys.spawn(race)
        print("BehaviorDropOnDeath: ", race.name)
    return Enums.Code.OK
    