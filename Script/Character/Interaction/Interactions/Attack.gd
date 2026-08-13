class_name Attack
extends InteractionBase

func interact(attacker: Character, defender: Character, _config: Array) -> Enums.Code:
    var result = attack(attacker, defender, defender, "Strength", "Defense", "Health")
    MsgHubChar.send_status_detected(attacker, "Detect=>熟能生巧", "Strength")
    MsgHubChar.send_status_detected(attacker, "Detect=>熟能生巧", "Defense")

    if (result.code == Enums.Code.OK):
        pass
    return result.code