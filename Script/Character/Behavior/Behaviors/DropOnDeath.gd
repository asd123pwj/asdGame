class_name DropOnDeath
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    for race in _char.inventories.get_DeadDrop():
        # CharSys.spawn(race)
        print("DropOnDeath: ", race.name)
    return Enums.Code.OK
    