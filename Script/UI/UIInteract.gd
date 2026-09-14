class_name UIInteract
extends BaseClass
## UI 交互指令宿主（设计见 Script/UI/UI.md）。
## 静态方法自动注册为指令（UIInteract.xxx），供元素按事件发送：
##   开启 UI   任意事件 → UIInteract.open_ui $parent.parent Menu $self
##   关闭      任意事件 → UIInteract.close $parent
##   按住拖动  逐帧状态 → UIInteract.drag $parent
##   渐隐/渐显  任意事件 → UIInteract.fade_to $parent 0.0 0.5
##   改显示内容 任意事件 → UIInteract.set_content $parent "新文本"
## target 为目标 UI 实例（指令里的 $parent/$self 由 resolve_cmd 转成 $@ID，
## 指令系统执行时已用 instance_from_id 取出实例，故这里收到的就是 UIBase）。
## 本类只做"指令参数 → 具体实现"的转发与校验，**不含任何 UI 策略**：
## 开启策略在 UiSys.open_ui，显示内容在 UIBase.content/refresh，可见性直接用 Control。


## 解析指令串占位符（由 UIBase.on_event 在发送前调用）：
##   $self          → 自身实例（$@ID）
##   $parent        → 父 UI；$parent.parent → 祖父，链式任意级。
##     级别不足时警告并用可达的最高级 parent 替代。
##     链尾若还跟着 ".xxx" 原样保留（成为 $@ID.xxx，指令系统会继续按表达式取该属性）。
## 被谁用：UIBase.on_event。
static func resolve_cmd(cmd: String, sender: UIBase) -> String:
	cmd = cmd.replace("$self", "$@" + str(sender.ID))
	var out := ""
	var i := 0
	while i < cmd.length():
		if cmd.substr(i, 7) == "$parent":
			var j := i + 7
			var levels := 1
			while cmd.substr(j, 7) == ".parent":
				levels += 1
				j += 7
			var ui := _climb_parent(sender, levels)
			out += "$@" + str(ui.ID)
			i = j
		else:
			out += cmd[i]
			i += 1
	return out


## 从 sender 沿 parent 向上爬 levels 级；不足时警告并返回可达的最高级。
## 被谁用：resolve_cmd。
static func _climb_parent(sender: UIBase, levels: int) -> UIBase:
	var cur: UIBase = sender
	var climbed := 0
	for i in levels:
		if cur.parent == null:
			@warning_ignore("unsafe_property_access")
			push_warning("UIInteract: 「%s」只向上 %d 级 parent（配置请求 %d 级），用可达的最高级替代" % [sender.name, climbed, levels])
			return cur
		cur = cur.parent
		climbed += 1
	return cur


## 开启一个 UI —— 指令入口：**不含任何"开/摆"策略，直接转发给唯一的实现 `UiSys.open_ui`**
## （普通 UI 与菜单同一条路；要改怎么开、怎么摆，只改那边）。
##   target      = 宿主（挂载点）。没有 anchor 时挂到它下面；
##                 **target 与 anchor 都不给就是独立 UI**（挂 UI 根）——指令里用 `--preset_name xxx` 跳过它。
##   preset_name = 预设名（见 Config/UI/）
##   anchor      = 位置锚点，同时是挂载点：多级菜单传"触发它的那个菜单项"，
##                 子菜单挂在该菜单项下 ⇒ 整条菜单链是一棵子树（关父级全关、失焦判定沿 parent 链）
## 指令写法：UIInteract.open_ui $self Menu $self        （面板右键 → 指针处开菜单）
##           UIInteract.open_ui --preset_name MiniHUD  （独立 UI → 开在配置声明的位置）
## 被谁用：Config/UI 里各预设的 "events"，以及 Test.ui_test（测试也走指令，不抄近路）。
static func open_ui(target: UIBase = null, preset_name: String = "", anchor: UIBase = null) -> void:
	UiSys.open_ui(preset_name, target, anchor)


## 关闭（隐藏）目标 UI：只是 hide，实例留在原地；**重开统一走 UIInteract.open_ui**
## （它会显示 + 按 open_at 重新摆位，不重建控件）——不要在这里加"再显示"的第二个入口。
## 被谁用：预设/菜单项里配 "UIInteract.close $parent" 之类；关闭按钮、菜单的"关闭"项。
static func close(target: UIBase) -> void:
	var ui := _as_ui(target, "close")
	if ui == null:
		return
	Msg.send_ui_close(ui)
	if ui.control != null:
		ui.control.hide()


## 拖动：把"指针本帧的累计位移"(InputSys.mouse_delta)作用到目标 UI 上。
## 由拖动手柄的逐帧状态（如 "Mouse Left | Tick"）驱动，一帧一次；指针不动时位移为 (0,0)，不会漂。
## 被谁用：预设里 "UIInteract.drag $parent"（标题栏），以及 enable_drag 追加的绑定。
static func drag(target: UIBase) -> void:
	var ui := _as_ui(target, "drag")
	if ui == null:
		return
	if ui.control != null:
		ui.control.position += InputSys.mouse_delta


## 透明度渐隐/渐显：alpha 为目标透明度(0~1)，duration 为补间秒数。
## 注意：经指令调用时参数须写全（指令系统 callv 不走 GDScript 默认值）。
## 被谁用：预设里 "UIInteract.fade_to $parent 0.0 0.5" 这类配置。
static func fade_to(target: UIBase, alpha: float, duration: float = 0.25) -> void:
	var ui := _as_ui(target, "fade_to")
	if ui == null:
		return
	Msg.send_ui_fade(ui, alpha)
	if ui.control != null:
		var tween: Tween = ui.control.create_tween()
		tween.tween_property(ui.control, "modulate:a", clampf(alpha, 0.0, 1.0), duration)


## 修改目标 UI 的显示内容（内部 set_content → refresh），如更新滚动区文本。
## 被谁用：预设里 "UIInteract.set_content $parent \"新文本\""；
## 外部改内容一般直接 get_ui(...).set_content(...)（见 Test.ui_test）。
static func set_content(target: UIBase, content: Variant) -> void:
	var ui := _as_ui(target, "set_content")
	if ui == null:
		return
	ui.set_content(content)


## 给目标 UI（宿主）的**右上角**加一个关闭按钮：占位实现是 Label 显示 "X" 的方块，点击关闭该 UI。
## 目标是容器时直接摆 position 会被布局覆盖，所以该元素声明 free 挂到叠加层（非容器），
## 位置用宿主坐标系算（挂载点原点即宿主原点）。已经加过就不重复加。
## 被谁用：菜单项"添加关闭按钮"（Config/UI/UIPreset_Menu.gd 的 MenuEdit/AddClose）。
static func add_close_button(target: UIBase) -> void:
	var ui := _as_ui(target, "add_close_button")
	if ui == null or ui.control == null:
		return
	for child in ui.children:
		if child.name == "CloseX":
			return
	var box: Vector2 = Vector2(20, 20)
	var btn: UIBase = ui.add_child_element("CloseX", "UI_Label", {
		"content": "X",
		"size": [box.x, box.y],
		"free": true,
		"events": [["Mouse Left", "UIInteract.close $parent"]],
	})
	if btn == null or btn.control == null:
		return
	btn.control.size = box
	btn.control.position = Vector2(ui.control.size.x - box.x, 0.0)


## 给目标 UI（宿主）启用拖拽：追加"<event_name> → 拖动自己"的事件绑定。
## 事件名由配置给（如 "Mouse Left | Tick"：逐帧状态，按住期间每帧拖一次）。
## 指令串里的 $self 指向"配了这条指令的元素"（即宿主 UI 本身），子元素上按住也能拖（事件冒泡）。
## 被谁用：菜单项"启用拖拽"（Config/UI/UIPreset_Menu.gd 的 MenuEdit/EnableDrag）。
static func enable_drag(target: UIBase, event_name: String) -> void:
	var ui := _as_ui(target, "enable_drag")
	if ui == null:
		return
	ui.add_event(event_name, "UIInteract.drag $self")


## target 校验：只接受 UIBase 实例（指令里的 $parent/$self 已由 resolve_cmd 转成 $@ID，
## 指令系统执行时用 instance_from_id 取出实例，所以这里收到的必是 UIBase）。
## 传空属配置或调用写错，报警告指明是哪个指令、传了什么，不要静默吞掉。
## 被谁用：本类除 open_ui 外的所有指令（open_ui 允许宿主为空 = 开独立 UI，故不校验）。
static func _as_ui(target: UIBase, cmd_name: String) -> UIBase:
	if target == null:
		push_warning("UIInteract.%s: target 为空（检查指令里的 $parent/$self 所在元素是否已正确组装）" % cmd_name)
		return null
	if target.control == null:
		push_warning("UIInteract.%s: 目标 UI「%s」尚未 build()（control 为空）" % [cmd_name, target.name])
	return target
