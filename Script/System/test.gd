class_name Test
extends RefCounted

var char_A: Character
var char_B: Character
var char_C: Character
var char_D: Character
var char_E: Character

func _init() -> void:
    pass
    ComboStatus.new([KEY_A, KEY_A])
    MsgHubInput.listen_combo([KEY_A, KEY_A], down_a)
    pass

func down_a(_msg) -> void:
    print(_msg)


func run() -> void:
    MsgHubSys.listen_spawn(char_spawn)
    char_A = CharSys.spawn("Human")
    char_B = CharSys.spawn("Rabbit")
    MsgHubChar.listen_status_satisfied(char_A, "Injured", char_injured)
    MsgHubChar.listen_status_satisfied(char_B, "Injured", char_injured)
    MsgHubChar.listen_status_satisfied(char_A, "Dead", char_died)
    MsgHubChar.listen_status_satisfied(char_B, "Dead", char_died)
    MsgHubChar.listen_status_satisfied(char_A, "Rebirth", char_rebirth)
    MsgHubChar.listen_status_satisfied(char_B, "Rebirth", char_rebirth)
    MsgHubChar.listen_status_satisfied(char_A, "Right", right)
    MsgHubChar.listen_status_satisfied(char_A, "On Left", left)
    MsgHubChar.listen_status_satisfied(char_A, "Up", up)
    print(Sys.sysCfg.random_seed)
    @warning_ignore("missing_await")
    # delay_loop_test()

func right(_msg: Character) -> void:
    print("角色 %s 向右移动" % _msg.name)

func left(_msg: Character) -> void:
    print("角色 %s 向左移动" % _msg.name)

func up(_msg: Character) -> void:
    print("角色 %s 向上移动" % _msg.name)

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
    for attr_type_name in char_.attrs.attributes.keys():
        info += " %s: %d" % [attr_type_name, char_.attrs.get_(attr_type_name)]
    print(info)


func delay_loop_test() -> void:
    Sys.msgBus.listen(TimeSys.msgID_advance, when_time_advance)
    get_char_info(char_A)
    get_char_info(char_B)
    
    for i in range(1000):
        await Sys.sys.get_tree().create_timer(1.0).timeout
        Sys.timeSys.advance()
        if RandSys.rand.randi_range(0, 1) == 0:
            print("A触摸B")
            MsgHubChar.send_status_detected(char_A, "Touch", char_B)
        # if RandSys.rand.randi_range(0, 3) == 0:
        #     print("B触摸A")
        #     MsgHubChar.send_status_detected(char_B, "Touch", char_A)

func when_time_advance(_msg: Variant) -> void:
    print("===================================")
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
