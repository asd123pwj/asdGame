class_name Test
extends RefCounted

var char_A: Character
var char_B: Character
var char_C: Character
var char_D: Character
var char_E: Character

func _init() -> void:
    pass
    MsgHubInput.listen_key_first_up([KEY_SHIFT, MOUSE_BUTTON_LEFT], down_a)
    MsgHubInput.listen_key_first_down([KEY_S, KEY_S], down_a)
    MsgHubInput.listen_key_down([KEY_S, KEY_S], down_a)
    MsgHubInput.listen_key_first_down([KEY_SHIFT, KEY_D, KEY_D], down_a)

    # MsgHubInput.listen_combo([KEY_A, KEY_A], down_a)
    pass

func down_a(_msg) -> void:
    print(_msg)


func run() -> void:
    char_A = CharSys.spawn("人类")
    char_B = CharSys.spawn("兔子")
    char_C = CharSys.spawn("草药")
    char_B.inventories.print_contents("DeadDrop")
    print(Sys.sysCfg.random_seed)
    @warning_ignore("missing_await")
    delay_loop_test()


func get_char_info(char_: Character) -> void:
    var info: String = char_.name
    for attr_type_name in char_.attrs.attributes.keys():
        info += " %s: %d" % [attr_type_name, char_.attrs.get_(attr_type_name)]
    print(info)


func delay_loop_test() -> void:
    MsgHubTime.listen_advance_hour(when_time_advance)
    # get_char_info(char_A)
    # get_char_info(char_B)
    MsgHubChar.send_status_detected(char_A, "Detect=>Nourish")

    # for i in range(1000):
    while false:
        await Sys.sys.get_tree().create_timer(1).timeout
        Sys.timeSys.advance()
        # if RandSys.rand.randi_range(0, 1) == 0:
        #     print("A触摸B")
        MsgHubChar.send_status_detected(char_A, "Detect=>Touch", char_B)
        # MsgHubChar.send_status_detected(char_A, "Detect=>Practice", "Strength")
        # MsgHubChar.send_status_detected(char_A, "Detect=>Practice", "Health")
        # MsgHubChar.send_status_detected(char_A, "Detect=>Practice", "Defense")

            # MsgHubChar.send_status_detected(char_B, "Detect=>Edible", char_C)
        # if RandSys.rand.randi_range(0, 3) == 0:
        #     print("B触摸A")
        #     MsgHubChar.send_status_detected(char_B, "Touch", char_A)

func when_time_advance(_msg: Variant) -> void:
    print("===================================")
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
