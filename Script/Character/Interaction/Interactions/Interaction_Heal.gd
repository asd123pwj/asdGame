class_name Interaction_Heal
extends InteractionBase

func interact(healer: Character, patient: Character) -> Array:
    var result := heal(healer, patient, patient, "Health", "Health", "Health")
    if result.code == Enums.Code.OK:
        Msg.send_status_detected(patient, "Detect=>CostHeal", healer)
    return [result]