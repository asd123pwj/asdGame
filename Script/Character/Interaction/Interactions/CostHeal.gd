class_name CostHeal
extends InteractionBase

func interact(patient: Character, healer: Character, _config: Array) -> Enums.Code:
    var result = cost(patient, patient, healer, "Health", "Health", "Health")
    return result.code