class_name Attack
extends InteractionBase

func interact(source: Character, target: Character, _config: Variant) -> Array[Enums.Code]:

    var result = attack(source, target, target, "Strength", "Defense", "Health")
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点伤害" % [source.name, target.name, abs(result.offset)])
        # get_char_info(char_A)
        # get_char_info(char_B)
    if (result.code == Enums.Code.FORBIDDEN):
        pass
        # print("%s 死亡" % [char_B.name])
    return [result.code]