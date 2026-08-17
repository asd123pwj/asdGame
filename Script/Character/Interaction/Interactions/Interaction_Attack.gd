class_name Interaction_Attack
extends InteractionBase

func interact(attacker: Character, defender: Character, _config) -> Enums.Code:
    # print(attacker.name, "攻击", defender.name)

    var result = attack(attacker, defender, defender, "Strength", "Defense", "Health")
    MsgHubChar.send_status_detected(attacker, "Detect=>Practice", "Strength")
    MsgHubChar.send_status_detected(defender, "Detect=>Practice", "Defense")
    if (result.code == Enums.Code.OK):
        pass
    return result.code