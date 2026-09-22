class_name Interaction_TryHealSelf
extends InteractionBase
## 自我治疗交互：翻背包，把可治疗的物品挑出来，对它们发"可食用"检测（后续由状态配置接治疗链）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_TryHealSelf"）。

## 遍历 Backpack，对每个"可治疗"物品发 Edible 检测。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(me: Character, _target: Character) -> Array:
    for item: Character in me.inventories.get_Backpack():
        if item.statuses.check_satisfied("Healable"):
            Msg.send_status_detected_transient(me, "Detect=>Edible", item)
    return [Enums.Code.OK]
