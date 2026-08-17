class_name Interaction_Eat
extends InteractionBase



func interact(source: Character, target: Character) -> Enums.Code:
    if target.statuses.check_satisfied("Healable"):
        # 注意source与target调换，因为source吃target后，是target治疗source
        return MsgHubChar.send_status_detected(target, "Detect=>Healable", source)
    return Enums.Code.NOT_FOUND