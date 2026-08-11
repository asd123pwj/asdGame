class_name Heal
extends InteractionBase

func interact(source: Character, target: Character, _config: Variant) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    var result = heal(source, target, target, "Health", "Health", "Health")
    codes.append(result.code)
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点治疗" % [source.name, target.name, abs(result.offset)])
        var result_消耗 = 消耗(target, target, source, "Health", "Health", "Health")
        codes.append(result_消耗.code)

    if (result.code == Enums.Code.FORBIDDEN):
        pass
        # print("%s 死亡" % [char_B.name])
    return codes