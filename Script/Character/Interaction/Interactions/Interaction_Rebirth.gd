class_name Interaction_Rebirth
extends InteractionBase
## 重生交互：把 Health 的 CUR 重置回基准值并结算掉已被消耗的 buff。
## 被谁用：InteractionPreset（interaction_name = "Interaction_Rebirth"）。

## 重生：重新初始化 Health 的当前值 + 消耗 buff。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(me: Character, _target) -> Array:
    me.attrs.init_attribute("Health", Enums.ValueType.CUR)
    me.attrs.consume_buffs("Health", Enums.ValueType.CUR)
    return [Enums.Code.OK]
