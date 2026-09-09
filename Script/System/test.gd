class_name Test
extends BaseClass

static var test_int := [{"value": [{"value": 5}]}] # [0].value[0].value
static var test_int2 := {"value": [-10]}
static var int1 := 1
static func test_func(a: int, b: int) -> int:
    return a + b

var char_A: Character
var char_B: Character
var char_C: Character
var char_D: Character
var char_E: Character

func _init() -> void:
    pass
    Msg.listen_key_first_up([KEY_SHIFT, MOUSE_BUTTON_LEFT], down_a)
    Msg.listen_key_first_down([KEY_S, KEY_S], down_a)
    Msg.listen_key_down([KEY_S, KEY_S], down_a)
    Msg.listen_key_first_down([KEY_SHIFT, KEY_D, KEY_D], down_a)

    # Msg.listen_combo([KEY_A, KEY_A], down_a)
    pass

func down_a(_msg) -> void:
    print(_msg)


func run() -> void:
    char_A = Msg.send_cmd00("CharSys.spawn 人类")
    # char_A = CharSys.spawn("人类")
    char_B = CharSys.spawn("兔子")
    char_C = CharSys.spawn("草药")
    # char_B.inventories.print_contents("DeadDrop")
    print(Sys.sysCfg.random_seed)
    ui_test()
    @warning_ignore("missing_await")
    delay_loop_test()


func ui_test() -> void:
    # UI 最小原型：从 UIPreset_Basic.values 取 MiniHUD 描述，UiBuilder 生成 Control 树并显示。
    var preset: UIPreset_Basic = UIPreset_Basic.new()
    var desc: Dictionary = {}
    for v in preset.values:
        if v.get("name", "") == "MiniHUD":
            desc = v
            break
    if desc.is_empty():
        print("UiBuilder: 未找到 MiniHUD 描述")
        return
    var r: Array = UiBuilder.build(desc, { "parent_style": {}, "track": null })
    if not r[0]:
        print("UiBuilder: 构建失败")
        return
    var root: Control = r[1]
    _dump_ui(root, 0)

    # 挂到主场景显示（临时 CanvasLayer）
    var layer: CanvasLayer = CanvasLayer.new()
    Sys.sys.get_tree().current_scene.add_child(layer)
    layer.add_child(root)


func _dump_ui(node: Node, depth: int) -> void:
    var pad: String = ""
    for i in depth:
        pad += "  "
    print(pad, node.get_class(), " / ", node.name)
    for c in node.get_children():
        var child: Node = c
        _dump_ui(child, depth + 1)


func get_char_info(char_: Character) -> void:
    var info: String = char_.name
    # for attr_type_name in char_.attrs.attributes.keys():
    for attr_type_name in Msg.send_cmd00("&@" + str(char_.ID) + ".attrs.attributes").keys():
        info += " %s: %d" % [attr_type_name, char_.attrs.get_(attr_type_name)]
    print(info)


func delay_loop_test() -> void:
    Msg.listen_advance_hour(when_time_advance)
    get_char_info(char_A)
    # get_char_info(char_B)
    Msg.send_status_detected(char_A, "Detect=>Nourish")

    await Sys.sys.get_tree().create_timer(1).timeout
    # for i in range(1000):
    while true:
        await Sys.sys.get_tree().create_timer(1).timeout
        
        MapSys.place(0, 5, -15, "门", "2", -1, true)
        # Msg.send_cmd("MapSys.place 0 $Test.test_int[0].value[0].value $Test.test_int2.value[0] 门 2 -1 true")
        Msg.send_cmd("MapSys.place 0 $Test.test_func($Test.int1, 4) $Test.test_int2.value[0] 门 2 -1 true")
        Msg.send_cmd("MapSys.place --layer_id 0 --x 10 --y -10 --source_name 门 --tile_name 2 --force_space")
        MapSys.build()
        # Sys.timeSys.advance()
        # if RandSys.rand.randi_range(0, 1) == 0:
        #     print("A触摸B")
        Msg.send_status_detected(char_A, "Detect=>Touch", char_B)
        # Msg.send_status_detected(char_A, "Detect=>Practice", "Strength")
        # Msg.send_status_detected(char_A, "Detect=>Practice", "Health")
        # Msg.send_status_detected(char_A, "Detect=>Practice", "Defense")

            # Msg.send_status_detected(char_B, "Detect=>Edible", char_C)
        # if RandSys.rand.randi_range(0, 3) == 0:
        #     print("B触摸A")
        #     Msg.send_status_detected(char_B, "Touch", char_A)

func when_time_advance(_msg: Variant) -> void:
    print("===================================")
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
