class_name Interaction_Eat
extends InteractionBase
## 进食交互：吃的一方对目标发"可治疗"检测（source/target 调换：吃下去的是"目标治疗自己"）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_Eat"）。

## 若目标可被治疗，就对它发 Healable 检测（后续治疗链路由状态配置去接）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(source: Character, target: Character) -> Array:
    if target.statuses.check_satisfied("Healable"):
        # 注意source与target调换，因为source吃target后，是target治疗source
        return Msg.send_status_detected_transient(target, "Detect=>Healable", source)
    return []
