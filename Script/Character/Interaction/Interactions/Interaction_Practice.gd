class_name Interaction_Practice
extends InteractionBase
## 练习（成长）交互：对某个属性做一次 practice 结算，让它的 CUR 向 BASE 靠拢。
## 属性名优先取配置里的字符串，没有就用检测消息带进来的属性名。
## 被谁用：InteractionPreset（interaction_name = "Interaction_Practice"）。

## 执行一次成长结算。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(user: Character, attr_name) -> Array:
    # print(user.name, "成长", attr_name)
    # 先用配置指定的属性名，没有则使用检测传入的属性名
    var str_attr_name: String
    if typeof(config) == TYPE_STRING:
        str_attr_name = config
    elif typeof(attr_name) == TYPE_STRING:
        str_attr_name = attr_name
    else:
        print("TODO: 报错，attr_name不是字符串")
    var result = practice(user, str_attr_name)
    if (result.code == Enums.Code.OK):
        # print(str_attr_name, "Practice", result.ori, "=>", result.new)
        pass
    return [result]
