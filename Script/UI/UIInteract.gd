class_name UIInteract
extends BaseClass
## UI 交互指令宿主（设计见 Script/UI/UI.md）。
## 静态方法自动注册为指令（UIInteract.xxx），供元素按事件发送：
##   按住拖动   move → UIInteract.drag $parent
##   关闭       press → UIInteract.close $parent
##   渐隐/渐显  任意事件 → UIInteract.fade_to $parent 0.0 0.5
##   改显示内容 任意事件 → UIInteract.set_content $parent "新文本"
## target 为目标 UI 实例（指令里的 $parent/$self 由 resolve_cmd 转成 $@ID，
## 指令系统执行时已用 instance_from_id 取出实例，故这里收到的就是 UIBase）。
## UIBase 只负责"展示 content + 存事件键→指令串"，解析与交互实现都在本类。


## 解析指令串占位符（由 UIBase._fire 在发送前调用）：
##   $self          → 自身实例（$@ID）
##   $parent        → 父 UI；$parent.parent → 祖父，链式任意级。
##     级别不足时警告并用可达的最高级 parent 替代。
##     链尾若还跟着 ".xxx" 原样保留（成为 $@ID.xxx，指令系统会继续按表达式取该属性）。
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


## 关闭（隐藏）目标 UI；再打开用 open。
static func close(target: UIBase) -> void:
	var ui := _as_ui(target, "close")
	if ui == null:
		return
	Msg.send_ui_close(ui)
	if ui.control != null:
		ui.control.hide()


## 重新显示目标 UI（与 close 成对）。
static func open(target: UIBase) -> void:
	var ui := _as_ui(target, "open")
	if ui == null:
		return
	if ui.control != null:
		ui.control.show()


## 拖动：把"鼠标相对上次事件移动的距离"(InputSys.mouse_delta)作用到目标 UI 上。
## 由拖动手柄的 move 指令在鼠标移动时逐次调用（无移动则无事件，不会重复套用）。
static func drag(target: UIBase) -> void:
	var ui := _as_ui(target, "drag")
	if ui == null:
		return
	if ui.control != null:
		ui.control.position += InputSys.mouse_delta


## 透明度渐隐/渐显：alpha 为目标透明度(0~1)，duration 为补间秒数。
## 注意：经指令调用时参数须写全（指令系统 callv 不走 GDScript 默认值）。
static func fade_to(target: UIBase, alpha: float, duration: float = 0.25) -> void:
	var ui := _as_ui(target, "fade_to")
	if ui == null:
		return
	Msg.send_ui_fade(ui, alpha)
	if ui.control != null:
		var tween: Tween = ui.control.create_tween()
		tween.tween_property(ui.control, "modulate:a", clampf(alpha, 0.0, 1.0), duration)


## 修改目标 UI 的显示内容（内部 set_content → refresh），如更新滚动区文本。
static func set_content(target: UIBase, content: Variant) -> void:
	var ui := _as_ui(target, "set_content")
	if ui == null:
		return
	ui.set_content(content)


## target 校验：只接受 UIBase 实例（指令里的 $parent/$self 已由 resolve_cmd 转成 $@ID，
## 指令系统执行时用 instance_from_id 取出实例，所以这里收到的必是 UIBase）。
## 传空属配置或调用写错，报警告指明是哪个指令、传了什么，不要静默吞掉。
static func _as_ui(target: UIBase, cmd_name: String) -> UIBase:
	if target == null:
		push_warning("UIInteract.%s: target 为空（检查指令里的 $parent/$self 所在元素是否已正确组装）" % cmd_name)
		return null
	if target.control == null:
		push_warning("UIInteract.%s: 目标 UI「%s」尚未 build()（control 为空）" % [cmd_name, target.name])
	return target
