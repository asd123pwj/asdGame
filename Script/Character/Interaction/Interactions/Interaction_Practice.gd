class_name Interaction_Practice
extends InteractionBase

func interact(user: Character, attr_name) -> Enums.Code:
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
    return result.code