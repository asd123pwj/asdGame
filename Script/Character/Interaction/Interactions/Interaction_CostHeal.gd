class_name Interaction_CostHeal
extends InteractionBase
## 治疗代价交互：被治疗的一方按"治疗前后血量差"付出代价（cost 套路，取 before 值算差额）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_CostHeal"）——通常由 Heal 成功后发出的检测触发。

## 执行一次"治疗代价"结算（patient 即付出方）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(patient: Character, healer: Character) -> Array:
    var result = cost(patient, patient, healer, "Health", "Health", "Health")
    return [result]
