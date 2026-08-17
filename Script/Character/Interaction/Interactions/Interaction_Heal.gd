class_name Interaction_Heal
extends InteractionBase

func interact(healer: Character, patient: Character, _config) -> Enums.Code:
    var result = heal(healer, patient, patient, "Health", "Health", "Health")
    if result.code == Enums.Code.OK:
        MsgHubChar.send_status_detected(patient, "Detect=>CostHeal", healer)
    return result.code