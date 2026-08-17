class_name Interaction_CostHeal
extends InteractionBase

func interact(patient: Character, healer: Character) -> Enums.Code:
    var result = cost(patient, patient, healer, "Health", "Health", "Health")
    return result.code