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
    MsgHubSys.listen_spawn(char_spawn)
    char_A = CharSys.spawn("Human")
    char_B = CharSys.spawn("Rabbit")
    MsgHubChar.listen_status_satisfied(char_A, "Injured", char_injured)
    MsgHubChar.listen_status_satisfied(char_B, "Injured", char_injured)
    # MsgHubChar.listen_status_unsatisfied(char_A, "Live", char_A_died)
    # MsgHubChar.listen_status_unsatisfied(char_B, "Live", char_B_died)
    MsgHubChar.listen_status_satisfied(char_A, "Dead", char_died)
    MsgHubChar.listen_status_satisfied(char_B, "Dead", char_died)
    MsgHubChar.listen_status_satisfied(char_A, "Rebirth", char_rebirth)
    MsgHubChar.listen_status_satisfied(char_B, "Rebirth", char_rebirth)
    # MsgHubChar.listen_type_change(char_A, "Health", char_A_injured)
    # MsgHubChar.listen_type_change(char_B, "Health", char_B_injured)
    print(Sys.sysCfg.random_seed)
    # var a = char_A.attr.attrs["食_食量"].get_random_level_base_on_cur_level()
    # print(a)
    @warning_ignore("missing_await")
    delay_loop_test()

func char_spawn(char_) -> void:
    print("角色 %s 生成" % char_.name)

func char_injured(_msg: Character) -> void:
    get_char_info(_msg)

func char_died(_msg: Character) -> void:
    print(_msg.name + "死亡")

func char_rebirth(_msg: Character) -> void:
    print(_msg.name + "复活")

func get_char_info(char_: Character) -> void:
    var info: String = char_.name
    for attr_type_name in char_.attr.attr_types.keys():
        info += " %s: %d" % [attr_type_name, char_.attr.get_level_cur(attr_type_name)]
    print(info)

func attack(char_A: Character, char_B: Character) -> Enums.Code:
    var result = AttrSys.impact(char_A, char_B, char_B, "Attack", "Defense", "Health")
    if (result.code == Enums.Code.OK) or (result.code == Enums.Code.FORBIDDEN):
        print("%s 对 %s 造成了 %d 点伤害" % [char_A.name, char_B.name, abs(result.offset)])
        # get_char_info(char_A)
        # get_char_info(char_B)
    if (result.code == Enums.Code.FORBIDDEN):
        pass
        # print("%s 死亡" % [char_B.name])
    return result.code

func delay_loop_test() -> void:
    Sys.msgBus.listen(TimeSys.msgID_advance, when_time_advance)
    get_char_info(char_A)
    get_char_info(char_B)
    
    for i in range(1000):
        # print("第 %d 秒" % i)   # 可选输出，便于观察进度
        Sys.timeSys.advance()
        attack(char_A, char_B)
        attack(char_B, char_A)
        # if attack(char_A, char_B) == Enums.Code.FORBIDDEN:
        #     break
        # if attack(char_B, char_A) == Enums.Code.FORBIDDEN:
            # break

        await Sys.sys.get_tree().create_timer(1.0).timeout

func when_time_advance(_msg: Variant) -> void:
    print("===================================")
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
