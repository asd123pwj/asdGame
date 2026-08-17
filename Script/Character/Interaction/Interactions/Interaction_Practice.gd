class_name Interaction_Practice
extends InteractionBase

func interact(user: Character, attr_name: String, _config) -> Enums.Code:
    # print(user.name, "成长", attr_name)

    var result = practice(user, attr_name)
    if (result.code == Enums.Code.OK):
        print(attr_name, "Practice", result.ori, "=>", result.new)
        pass
    return result.code