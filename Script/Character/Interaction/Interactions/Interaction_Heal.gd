class_name Interaction_Heal
extends InteractionBase
## 治疗交互：治疗者与患者比 Health，差额加到患者的 Health 上；成功后给患者发"消耗治疗"检测。
## 被谁用：InteractionPreset（interaction_name = "Interaction_Heal"）。

## 执行一次治疗结算。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(healer: Character, patient: Character) -> Array:
    var result := heal(healer, patient, patient, "Health", "Health", "Health")
    if result.code == Enums.Code.OK:
        Msg.send_status_detected(patient, "Detect=>CostHeal", healer)
    return [result]
