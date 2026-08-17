class_name Interaction_DropOnDeath
extends InteractionBase

func interact(me: Character, _target: Character) -> Enums.Code:
    for race in me.inventories.get_DeadDrop():
        # CharSys.spawn(race)
        print("BehaviorDropOnDeath: ", race.name)
    return Enums.Code.OK