class_name Attack
extends RefCounted


static func interact(actor: Character, target: Character, config: Array) -> Enums.Code:
    var result = AttrSys.impact(actor, target, target, config[0], config[1], config[2])
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点伤害" % [actor.name, target.name, abs(result.offset)])
        # get_char_info(char_A)
        # get_char_info(char_B)
    if (result.code == Enums.Code.FORBIDDEN):
        pass
        # print("%s 死亡" % [char_B.name])
    return result.code