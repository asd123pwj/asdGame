class_name Attack
extends InteractionBase

func interact(attacker: Character, defender: Character, _config: Array) -> Enums.Code:
    var result = attack(attacker, defender, defender, "Strength", "Defense", "Health")
    if (result.code == Enums.Code.OK):
        pass
    return result.code