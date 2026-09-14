class_name Interaction_SayChanged
extends InteractionBase
## 播报交互：把"某个属性在谁的影响下从多少变到多少"拼成一句话打印出来（属性变化的消息化）。
## 属性名由检测消息带进来（target 是字符串时即为属性名）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_SayChanged"）。

## 打印一句变化播报（target 不是字符串则什么都不做）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(me: Character, _target) -> Array:
    if typeof(_target) == TYPE_STRING:
        var attr_name = _target
        var value_before = me.attrs.get_(attr_name, Enums.ValueType.CUR, true)
        var value_cur = me.attrs.get_(attr_name, Enums.ValueType.CUR)
        var changed_by_how = me.attrs.get_changed_by_how(attr_name)
        var changed_by_who = me.attrs.get_changed_by_who(attr_name)
        print("在" + changed_by_who.name + "的" + changed_by_how + "影响下，" + me.name + "的" + attr_name + "从" + str(value_before) + "变为" + str(value_cur) + "。")

    return [Enums.Code.OK]
