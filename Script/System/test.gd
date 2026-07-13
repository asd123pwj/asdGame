class_name Test
extends RefCounted

var char_A: Character
var char_B: Character
var char_C: Character
var char_D: Character
var char_E: Character

func _init() -> void:
    pass

func run() -> void:
    char_A = Character.new("角色1", "Human A")
    char_B = Character.new("角色2", "Human B")

    print(Sys.sys_cfg.random_seed)
    # var a = char_A.attr.attrs["食_食量"].get_random_level_base_on_cur_level()
    # print(a)
    delay_loop_test()

func get_char_info(char_: Character) -> void:
    var info: String = char_.name
    for attr_type_name in char_.attr.attr_types.keys():
        info += " %s: %d" % [attr_type_name, char_.attr.get_level_cur(attr_type_name)]
    print(info)

func attack(char_A: Character, char_B: Character) -> Enums.Code:
    var result = AttributeSystem.impact(char_A, char_B, char_B, "Attack", "Defense", "Health")
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点伤害" % [char_A.name, char_B.name, abs(result.offset)])
        get_char_info(char_A)
        get_char_info(char_B)
    if (result.code == Enums.Code.FORBIDDEN):
        print("%s 死亡" % [char_A.name])
    return result.code

func delay_loop_test() -> void:
    Sys.msgBus.add_receiver(TimeSystem.msgID_advance, when_time_advance)
    get_char_info(char_A)
    get_char_info(char_B)
    
    for i in range(1000):
        # print("第 %d 秒" % i)   # 可选输出，便于观察进度
        Sys.timeSys.advance()
        if attack(char_A, char_B) == Enums.Code.FORBIDDEN:
            break
        if attack(char_B, char_A) == Enums.Code.FORBIDDEN:
            break

        await Sys.sys.get_tree().create_timer(1.0).timeout

func when_time_advance(_msg: Variant) -> void:
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
