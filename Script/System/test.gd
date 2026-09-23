class_name Test
extends BaseClass
## 项目自用的演示/联调脚本（不是正式系统逻辑，可以随意改）。
## 由 Sys._ready 里 `_test.run()` 触发，里面既演示各系统的用法，也兼作"改完先跑一遍"的冒烟测试。
## 被谁用：Sys._ready（唯一入口）。

static var test_int := [{"value": [{"value": 5}]}] # [0].value[0].value
static var test_int2 := {"value": [-10]}
static var int1 := 1
## 指令系统的取值示例（见 CommandSystem.gd 顶部说明）：
## 用 `Test.test_int[0].value[0].value`、`Test.test_func(Test.int1, 4)` 这类写法把静态成员/函数当参数。
## 被谁用：delay_loop_test 里的 Msg.send_cmd 示例。
static func test_func(a: int, b: int) -> int:
    return a + b

var char_A: Character
var char_B: Character
var char_C: Character
var char_D: Character
var char_E: Character

## 起手挂几条按键监听，用来调消息链路（含组合键的注释示例）。
## 被谁用：Sys._ready（`var _test = Test.new()` 时构造）。
func _init() -> void:
    pass
    Msg.listen_key_release([KEY_SHIFT, MOUSE_BUTTON_LEFT], down_a)
    Msg.listen_key_press([KEY_S, KEY_S], down_a)
    Msg.listen_key_hold([KEY_S, KEY_S], down_a)
    Msg.listen_key_press([KEY_SHIFT, KEY_D, KEY_D], down_a)

    # Msg.listen_combo([KEY_A, KEY_A], down_a)
    pass

## 调试回调：把收到的消息原样打印。
## 被谁用：_init 里那几条 listen_key_*。
func down_a(_msg) -> void:
    print(_msg)


## 冒烟入口：生成几个角色 → 开 UI → 起延迟循环。
## 被谁用：Sys._ready。
func run() -> void:
    char_A = CharSys.spawn("人类", "player")
    # char_A = CharSys.spawn("人类")
    char_B = CharSys.spawn("兔子")
    char_C = CharSys.spawn("草药")
    # char_B.inventories.print_contents("DeadDrop")
    print(Sys.sysCfg.random_seed)
    ui_test()
    @warning_ignore("missing_await")
    delay_loop_test()



## UI 演示：**开启路径与游戏内完全一致**（发指令 UIInteract.open，不直接调内部函数）。
## 被谁用：run。
func ui_test() -> void:
    # UI 演示（设计见 Script/UI/UI.md）：UIPreset 配置 → UIInteract_OpenClose.open 统一开启 → UIBase 包装 Control。
    # 开启方式与游戏里**完全一致**：发指令（UIInteract.open），不直接调内部函数——
    # 全项目开 UI 只有这一条路，改了才会全都被改到。想手动开关就绑快捷键到这个指令上。
    Msg.send_cmd("UIInteract.open(preset_name=\"MiniHUD\")")
    var ui: UIBase = UISys.get_ui("UI/MiniHUD")
    if ui == null:
        print("UI: MiniHUD 没开出来（查预设与 UIInteract.open）")
        return
    # 交互一律走 Msg（不用自定义 signal）；指针输入由 PointerDetect 用 InputSys 检测命中后派发。
    Msg.listen_ui_close(ui, func(_m): print("UI close"))
    Msg.listen_ui_submit(ui, func(_m): print("UI submit"))
    Msg.listen_ui_fade(ui, func(m): print("UI fade -> ", m))
    # 展示 content/refresh 流程：修改内容属性即可更新滚动条 UI（不必重建控件）
    var info: UIBase = UISys.get_ui("UI/MiniHUD/Info")
    if info != null:
        var lines: PackedStringArray = PackedStringArray()
        for i in range(40):
            lines.append("第 %d 行：滚动查看内容。" % i)
        info.config["content"] = "\n".join(lines)
        info.refresh("content")     # 只改了 content 就只刷它（不传 key = 全刷）

    # 键盘快捷键界面（见 Config/UI/UIPreset_Keyboard.gd）：独立 UI + 右上角关闭按钮 / 右下角缩放手柄。
    # "给面板加个按钮"就是开一个普通预设（CloseButton / ResizeButton），不写专门函数；
    # 指令里引用实例写 **`@注册名`**（配置里写的是 `@self` / `@host` / `@event`，由指令系统在派发时解析；
    # 这里是"事件之外"发的指令，没有 `@self` 可解析，所以手写完整注册名——UI 的登记名都带 `UI/` 前缀）。
    Msg.send_cmd("UIInteract.open(preset_name=\"Keyboard\")")
    Msg.send_cmd('UIInteract.open(@UI/Keyboard, "CloseButton", @UI/Keyboard)')
    Msg.send_cmd('UIInteract.open(@UI/Keyboard, "ResizeButton", @UI/Keyboard)')

    # 测试用的两个 UI：显示（TestShow）/ 输入（TestInput）——J / K 键开关它们
    # 玩法：右键 TestShow → 复制名称 → 右键 TestInput → 绑定 ▸ → 回车，然后在输入框里打字回车
    Msg.send_cmd("UIInteract.open(preset_name=\"TestShow\")")
    Msg.send_cmd("UIInteract.open(preset_name=\"TestInput\")")

    # 长内容 / 可收回演示（Config/UI/UIPreset_Fold.gd）：整块能收成一个标题，三段各自也能收
    Msg.send_cmd("UIInteract.open(preset_name=\"FoldDemo\")")

    # UI 编辑器（外壳 Config/UI/UIPreset_Editor.gd + 内容元素 Script/UI/UI/UI_Editor.gd）：
    # 平时从"右键 UI → 菜单编辑 → UI 编辑器"打开；这里默认开一份方便直接看效果。
    # 开它就是**一条通用 open**（内容由编辑器元素按配置自己铺；没有专用的开启指令）
    # （被编辑 UI 的 config 每项一行，子UI每段一行且**默认收起**，展开哪段才铺那段）
    Msg.send_cmd('UIInteract.open(@UI/MiniHUD, "Editor", @UI/MiniHUD, host=@UI/MiniHUD)')

    # 角色状态一览（外壳 Config/UI/UIPreset_Status.gd + 内容元素 Script/UI/UI/UI_Status.gd）：
    # 独立 UI，看哪个角色由预设里 Body 的 `char` 决定（默认 @Char/SYS）。
    # 换人：UIInteract.open(preset_name="Status", content_cmd="@Char/人类")。
    Msg.send_cmd('UIInteract.open(preset_name="Status")')

    # 角色快捷监控（外壳 Config/UI/UIPreset_Shortcut.gd + 内容元素 Script/UI/UI/UI_Shortcut.gd）：
    # 每条快捷两行：名称 / "依赖状态 → 执行的指令"。同样默认看 @Char/SYS，换人写 content_cmd。
    Msg.send_cmd('UIInteract.open(preset_name="Shortcut")')

    # 角色属性 / Buff 一览（外壳 Config/UI/UIPreset_Attr.gd + 内容元素 Script/UI/UI/UI_Attr.gd）：
    # 每个类别一段（当前值 / 改动前 / 改动来源 / 参与 Buff）。默认看 char_A，也就是上面 spawn("人类","player") 那个。
    # 换人：UIInteract.open(preset_name="Attr", content_cmd="@Char/兔子")。
    Msg.send_cmd('UIInteract.open(preset_name="Attr")')

## 打印角色全部属性（演示"用指令取属性字典再遍历"的写法）。
## 被谁用：delay_loop_test。
func get_char_info(char_: Character) -> void:
    var info: String = char_.name
    # 属性字典：直接用指令取出（send_cmd00 返回 Variant，按 Dictionary 收下再遍历）
    # 不用指令时的等价写法：for attr_type_name in char_.attrs.attributes.keys():
    var attrs: Dictionary = Msg.send_cmd00("@%s.attrs.attributes" % RegSys.name_of(char_))
    for attr_type_name in attrs.keys():
        info += " %s: %d" % [attr_type_name, char_.attrs.get_(attr_type_name)]
    print(info)


## 每秒跑一轮的联调循环：地图放置/构建、状态检测、指令取值示例都在这儿。
## 被谁用：run（里面的 while true 会一直转，所以 run 里加了 missing_await 抑制）。
func delay_loop_test() -> void:
    Msg.listen_advance_hour(when_time_advance)
    get_char_info(char_A)
    # get_char_info(char_B)
    Msg.send_status_detected_transient(char_A, "Detect=>Nourish")

    await Sys.sys.get_tree().create_timer(1).timeout
    # for i in range(1000):
    while true:
        await Sys.sys.get_tree().create_timer(1).timeout
        
        MapSys.place(0, 5, -15, "门", "2", -1, true)
        # Msg.send_cmd("MapSys.place 0 Test.test_int[0].value[0].value Test.test_int2.value[0] 门 2 -1 true")
        Msg.send_cmd("MapSys.place(0, Test.test_func(Test.int1, 4), Test.test_int2.value[0], \"门\", 2, -1, true)")
        Msg.send_cmd("MapSys.place(layer_id=0, x=10, y=-10, source_name=\"门\", tile_name=2, force_space=true)")
        MapSys.build()
        # Sys.timeSys.advance()
        # if RandSys.rand.randi_range(0, 1) == 0:
        #     print("A触摸B")
        Msg.send_status_detected_transient(char_A, "Detect=>Touch", char_B)
        # Msg.send_status_detected_transient(char_A, "Detect=>Practice", "Strength")
        # Msg.send_status_detected_transient(char_A, "Detect=>Practice", "Health")
        # Msg.send_status_detected_transient(char_A, "Detect=>Practice", "Defense")

            # Msg.send_status_detected_transient(char_B, "Detect=>Edible", char_C)
        # if RandSys.rand.randi_range(0, 3) == 0:
        #     print("B触摸A")
        #     Msg.send_status_detected_transient(char_B, "Touch", char_A)

## 时间推进回调：打印当前中文时间（演示 TimeSys → TimeFormat 的用法）。
## 被谁用：delay_loop_test 里 listen_advance_hour 的回调。
func when_time_advance(_msg: Variant) -> void:
    print("===================================")
    print(TimeFormat.year + TimeFormat.month + TimeFormat.day + TimeFormat.hour)
