class_name 熟能生巧
extends InteractionBase

func interact(user: Character, attr_name: String, _config: Array) -> Enums.Code:
    var result = 熟能生巧(user, attr_name)
    if (result.code == Enums.Code.OK):
        print(attr_name, "熟能生巧", result.ori, "=>", result.new)
        pass
    return result.code