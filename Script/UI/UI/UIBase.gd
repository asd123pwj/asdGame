class_name UIBase
extends BaseClass
## UI 元素基类（设计见 Script/UI/UI.md）。
## extends BaseClass，内部持 control: Control（不直接继承 Control）。
## 指针输入由 PointDetect 用 InputSys 检测命中后回调本对象（不用引擎 gui_input）。
## 交互**不用开关**（draggable/closeable 等已移除），而是"事件→指令"：
## config 里按事件键（"press"/"move"/"release"/"submit"）配指令串，事件发生即发送；
## 占位符解析与交互实现都在 UIInteract（UIBase 只存"何时发什么指令"）：
##   $self → 自身实例；$parent → 父 UI；$parent.parent → 祖父（链式任意级，级别不足警告并用最高可达级）。
## 显示内容统一挂 var content，子类 refresh() 把它刷到控件上。

var name: String = ""
var config: Dictionary = {}
var control: Control

## 显示内容：指明该 UI 展示什么（文本/多行文本…由子类解释）。
## 修改展示 = set_content(v)（内部自动 refresh），或改 content 后手动调 refresh()。
var content: Variant = null

## 挂载对象（父 UI）：组装子元素时由父元素注入，即指令占位符 $parent 的指向。
var parent: UIBase = null

## 子元素：build() 按 config["children"] 组装，每项 [child_name, ui_class, child_config]。
var children: Array[UIBase] = []


func _init(name_: String = "", config_: Dictionary = {}) -> void:
	name = name_
	config = config_


## 生成控件树并组装子元素，返回 control（供 UiSystem 挂载）。指针交互由 PointDetect 驱动。
func build() -> Control:
	control = _create_control()
	_apply_config()
	refresh()
	_build_children()
	return control


## 虚接口：子类生成自身外观控件。
func _create_control() -> Control:
	return Control.new()


## 虚接口：把 content 刷到控件上（子类覆写）。
func refresh() -> void:
	pass


## 修改显示内容并立即刷新。
func set_content(value: Variant) -> void:
	content = value
	refresh()


## 子元素挂载点（默认直接挂 control；容器类覆写返回内部布局节点）。
func _content_box() -> Control:
	return control


func _apply_config() -> void:
	if config.has("position") and config["position"] is Array:
		var p: Array = config["position"]
		if p.size() >= 2:
			control.position = Vector2(float(p[0]), float(p[1]))
	if config.has("size") and config["size"] is Array:
		var s: Array = config["size"]
		if s.size() >= 2:
			control.custom_minimum_size = Vector2(float(s[0]), float(s[1]))
			control.size = control.custom_minimum_size
	if config.has("content"):
		content = config["content"]


## 组装子元素：config["children"] 每项 [child_name, ui_class, child_config]。
## 子元素的挂载对象（parent）即本元素（父 UI），其指令里的 $parent 指向本元素。
func _build_children() -> void:
	var box: Control = _content_box()
	for item_raw in config.get("children", []):
		if not (item_raw is Array):
			continue
		var item: Array = item_raw
		if item.size() < 2:
			continue
		var child_config: Dictionary = item[2] if item.size() > 2 else {}
		var child: UIBase = UIPreset.create_element(item[0], item[1], child_config)
		if child == null:
			continue
		child.parent = self
		child.build()
		children.append(child)
		box.add_child(child.control)


## 指针按下（PointDetect 派发）：发送 config["press"] 指令。
func on_pointer_press() -> void: _fire("press")
func on_pointer_move() -> void: _fire("move")
func on_pointer_release() -> void: _fire("release")
func on_submit() -> void: _fire("submit")
## 事件→指令：统一只做"查事件键 → 发指令"，事件键本身区分按下/移动/抬起/提交；
## 未配置指令的事件不发送（无默认回退），元素没有额外隐式行为。
## 占位符（$self/$parent 链）由 UIInteract.resolve_cmd 解析。
func _fire(event_kind: String) -> void:
	var cmd: String = config.get(event_kind, "")
	if cmd != "":
		Msg.send_cmd(UIInteract.resolve_cmd(cmd, self))
