class_name Heal
extends InteractionBase

func _init() -> void:
    source_attr_category = "Health"
    compare_attr_category = "Health"
    target_attr_category = "Health"
    like_heal()

func interact(source: Character, target: Character, _config: Variant) -> Enums.Code:

    var result = impact(source, target, target)
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点治疗" % [source.name, target.name, abs(result.offset)])
        
        # get_char_info(char_A)
        # get_char_info(char_B)
    if (result.code == Enums.Code.FORBIDDEN):
        pass
        # print("%s 死亡" % [char_B.name])
    return result.code