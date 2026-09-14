class_name UIBase
extends BaseClass
## UI 元素基类（设计见 Script/UI/UI.md）。
## extends BaseClass，内部持 control: Control（不直接继承 Control）。
## 指针输入由 PointerDetect 用 InputSys 检测命中后回调本对象（不用引擎 gui_input）。
## 交互**不用开关**（draggable/closeable 等已移除），而是"事件→指令"：
## config["events"] 是 [事件名, 指令串] 的列表，事件发生即发送对应指令。
## 事件名就是**状态名**（如 "Mouse Left"）：UI 不关心键位，键位只在状态层（statuses 的 keys）配置；
## hover 变化不对应任何状态，用 PointerDetect.EVENT_POINTER_ENTER / EVENT_POINTER_EXIT。
## 占位符解析与交互实现都在 UIInteract（UIBase 只存"何时发什么指令"）；
## 开启与登记在 UiSystem.open_ui（**全项目唯一的开启入口**）。
## 显示内容统一挂 var content，子类 refresh() 把它刷到控件上。

## 元素名：登记名的一段（独立 UI 就是预设名，子元素就是配置里写的名字）。
## 被谁用：UiSystem._register_tree / find_name（拼登记名）、各处的警告文案。
var name: String = ""
## 本元素的配置（见 Config/UI/）。公共属性：position/size/content/children/events/visible/free，
## 各子类另有自己的（如菜单的 open_at / close_on_blur）。
## 被谁用：_apply_config、_build_children、on_event、UiSystem._place（读 open_at）。
var config: Dictionary = {}
## 真正的引擎控件（本元素外观的根，子节点也挂在它下面）。
## 被谁用：UiSystem（挂载）、PointerDetect._ui_at（命中矩形）、UIInteract 各指令、UiSystem._place。
var control: Control

## 显示内容：指明该 UI 展示什么（文本/多行文本/纹理路径…由子类解释）。
## 修改展示 = set_content(v)（内部自动 refresh），或改 content 后手动调 refresh()。
## 被谁用：_apply_config（从配置取）、子类 refresh（读）、UIInteract.set_content（指令写）。
var content: Variant = null

## 挂载对象（父 UI）：组装子元素时由父元素注入，即指令占位符 $parent 的指向。
## 被谁用：_build_children / add_child_element（注入）、UIInteract.resolve_cmd（$parent 链）、
##         on_event（事件冒泡）、UI_Menu.nearest / find_instance（判定宿主与菜单链）。
var parent: UIBase = null

## 子元素：build() 按 config["children"] 组装，每项 [child_name, ui_class, child_config]。
## 被谁用：_build_children / add_child_element（追加）、UiSystem._register_tree（递归登记）、
##         UIInteract.add_close_button（查重）。
var children: Array[UIBase] = []


## 构造：只记名字与配置，控件在 build() 里才建。
## 被谁用：UIPreset.create_element（唯一的实例化工厂）→ UIPreset._get_ui_by_name。
func _init(name_: String = "", config_: Dictionary = {}) -> void:
	name = name_
	config = config_


## 生成控件树并组装子元素，返回 control（供 UiSystem 挂载）。
## 顺序不能换：建控件 → 应用配置 → 刷内容 → 建子元素 → 补尺寸（子元素建完才知道内容多大）。
## 被谁用：UiSystem._build_open（独立 UI 与寄主型都走它）、_build_children / add_child_element（子元素）。
func build() -> Control:
	control = _create_control()
	_apply_config()
	refresh()
	_build_children()
	_fit_size()
	return control


## size 配置里为 0 的那一维，按"内容最小尺寸"补足（要等子元素建完才知道内容多大）。
## 于是 [宽, 0] = 宽固定、高随内容；[0, 0] = 完全由内容决定。
## 注意必须补：控件尺寸为 0 时 get_global_rect() 是退化矩形，
## PointerDetect 永远命中不到它（菜单这类"宽固定、高随内容"的面板就靠这一步）。
## 被谁用：build()；UI_Panel 另在 _panel.minimum_size_changed 时重调
##         （建时还没进树、字体主题问不出来，内容多大要等容器排完版才知道）。
func _fit_size() -> void:
	var want: Vector2 = control.custom_minimum_size
	if want.x > 0.0 and want.y > 0.0:
		return
	var need: Vector2 = _content_size()
	control.size = Vector2(want.x if want.x > 0.0 else need.x, want.y if want.y > 0.0 else need.y)


## 内容本身需要多大（默认取控件的最小尺寸）。
## 容器类要覆写：**普通 Control 不会汇总子元素的最小尺寸**，
## 这时必须问内部真正的容器（它才带着边距 + 内容），否则 size 里为 0 的那一维会补成 0，
## 得到一个高度为 0 的退化矩形（画不出来，也命中不到）。
## 被谁用：_fit_size。覆写者：UI_Panel。
func _content_size() -> Vector2:
	return control.get_combined_minimum_size()


## 虚接口：子类生成自身外观控件。
## 被谁用：build()。实现者：UI_Panel / UI_Label / UI_Scroll / UI_Image。
func _create_control() -> Control:
	return Control.new()


## 虚接口：把 content 刷到控件上（子类覆写）。
## 被谁用：build() 末尾、set_content()。实现者：UI_Label / UI_Scroll / UI_Image。
func refresh() -> void:
	pass


## 修改显示内容并立即刷新。
## 被谁用：UIInteract.set_content（指令）、外部直接调（如 Test.ui_test 改滚动区文本）。
func set_content(value: Variant) -> void:
	content = value
	refresh()


## 摆到指定**屏幕坐标**并显示（按 open_at 策略开的 UI 用，见 UiSystem._place）。
## 位置换算成"挂载点坐标系"的 position：
##   - 不用 set_global_position——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏；
##   - 也不设 Control.top_level——那会让元素不再继承父级可见性（父级 hide 后它还留在屏幕上、也还能被命中）。
## 被谁用：UiSystem._place（POINTER / ANCHOR_TOP_RIGHT 两种策略）。
func show_at(pos: Vector2) -> void:
	if control == null:
		return
	var box: Control = control.get_parent() as Control
	var origin: Vector2 = box.get_global_rect().position if box != null else Vector2.ZERO
	control.position = pos - origin
	control.show()


## 摆回配置里声明的位置（config["position"]）；没配就不动。
## 被谁用：_apply_config（建时）、UiSystem._place（CONFIG 策略：被拖动过的 UI 重开时回初值）。
func reset_position() -> void:
	if control == null:
		return
	if config.has("position") and config["position"] is Array:
		var p: Array = config["position"]
		if p.size() >= 2:
			control.position = Vector2(float(p[0]), float(p[1]))


## 子元素挂载点（默认直接挂 control；容器类覆写返回内部布局节点）。
## 被谁用：_build_children、add_child_element。
func _content_box() -> Control:
	return control


## 自由定位子元素的挂载点（默认与 _content_box 相同；容器类应覆写成"非容器的叠加层"，
## 否则 position 会被父级布局覆盖）。
## 被谁用：add_child_element（配置里声明 free 的子元素，如菜单）。覆写者：UI_Panel。
func _free_box() -> Control:
	return _content_box()


## 应用 config 里的公共属性：position / size / content / visible。
## 被谁用：build()。子类覆写时必须先 super()（如 UI_Scroll 之后调 label 尺寸、UI_Menu 之后记实例）。
func _apply_config() -> void:
	reset_position()
	if config.has("size") and config["size"] is Array:
		var s: Array = config["size"]
		if s.size() >= 2:
			control.custom_minimum_size = Vector2(float(s[0]), float(s[1]))
			control.size = control.custom_minimum_size
	if config.has("content"):
		content = config["content"]
	if config.has("visible"):
		control.visible = bool(config["visible"])


## 组装子元素：config["children"] 每项 [child_name, ui_class, child_config]。
## 子元素的挂载对象（parent）即本元素（父 UI），其指令里的 $parent 指向本元素。
## 被谁用：build()。（运行时加子元素走 add_child_element，那条路要额外登记。）
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


## 唯一事件入口（PointerDetect 派发）：参数是事件名——状态驱动的事件就是配置里的状态名
## （如 "Mouse Left"、"Mouse Left | Tick"；UI 不感知按键，键位只在状态层出现），
## hover 变化用 PointerDetect.EVENT_POINTER_ENTER / EVENT_POINTER_EXIT。
## 事件→指令：在 config["events"]（[事件名, 指令串] 列表）里按等值取指令串，取到才发送。
## 自己没配的事件**冒泡给父级**：于是"整块面板的行为"在它的子元素上同样生效
## （如菜单面板启用拖拽后，按住菜单项也能拖；$self/$parent 以配了指令的那个元素为基准）。
## 冒泡到根仍没有配置就什么都不做（元素没有隐式行为）。
## 用列表而不是字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），
## 且要加新事件只需往列表里加一项。
## 占位符（$self/$parent 链）由 UIInteract.resolve_cmd 解析。
## 被谁用：PointerDetect.key（状态事件）、PointerDetect.update_targets（enter/exit）、本函数自身（冒泡）。
func on_event(event_name: Variant) -> void:
	for entry in config.get("events", []):
		if not (entry is Array):
			push_warning("UIBase「%s」: config[\"events\"] 的项应为 [事件名, 指令串]，收到 %s" % [name, type_string(typeof(entry))])
			continue
		var pair: Array = entry
		if pair.size() >= 2 and pair[0] == event_name:
			var cmd: String = pair[1]
			Msg.send_cmd(UIInteract.resolve_cmd(cmd, self))
			return
	if parent != null:
		parent.on_event(event_name)


## 运行时追加一个子元素（如菜单里后加的关闭按钮），返回新元素。
## 生成控件 → 挂到 _content_box()/_free_box() → 记进 children → 交给 UiSystem 登记
## （登记后才可能被指针命中；登记名规则在 UiSystem）。
## 被谁用：UiSystem._build_open（菜单这类寄主型 UI）、UIInteract.add_close_button。
func add_child_element(child_name: String, ui_class: String, child_config: Dictionary = {}) -> UIBase:
	var child: UIBase = UIPreset.create_element(child_name, ui_class, child_config)
	if child == null:
		return null
	child.parent = self
	child.build()
	children.append(child)
	# 配置里声明 free 的当"自由定位"元素：挂到叠加层，位置才不会被父级容器布局覆盖。
	# 注意不要给它设 Control.top_level——那样它就不再继承父级可见性，宿主关了它还会留在屏幕上；
	# 摆放时把屏幕坐标换算成挂载点坐标系的 position 即可（见 UiSystem._place）。
	var box: Control = _free_box() if bool(child_config.get("free", false)) else _content_box()
	box.add_child(child.control)
	Sys.uiSys.register_child(self, child)
	return child


## 运行时追加一条事件绑定（如"启用拖拽"）。语义与 config["events"] 完全一致，随时可加。
## 被谁用：UIInteract.enable_drag。
func add_event(event_name: String, cmd: String) -> void:
	var events: Array = config.get("events", [])
	events.append([event_name, cmd])
	config["events"] = events
