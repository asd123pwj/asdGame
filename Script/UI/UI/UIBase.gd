class_name UIBase
extends BaseClass
## UI 元素基类（设计见 Script/UI/UI.md）。
## extends BaseClass，内部持 control: Control（不直接继承 Control）。
## 指针输入由 PointerDetect 用 InputSys 检测命中后回调本对象（不用引擎 gui_input）。
## 交互**不用开关**（draggable/closeable 等已移除），而是"事件→指令"：
## config["events"] 是 [事件名, 指令串] 的列表，事件发生即发送对应指令。
## 事件名就是**状态名**（如 "Mouse Left"）：UI 不关心键位，键位只在状态层（statuses 的 keys）配置；
## hover 变化不对应任何状态，用 QName.pointer_enter / QName.pointer_exit。
## 占位符解析与交互实现都在 UIInteract（UIBase 只存"何时发什么指令"）；
## 登记与寻址在 UiSys（登记表 + 登记名规则）；**开启**在 UIInteract_OpenClose.open
## （**全项目唯一的开启入口**，指令形式 `UIInteract.open`）。
## 显示内容统一挂 var content，子类 refresh() 把它刷到控件上。

## 元素名：登记名的一段（独立 UI 就是预设名，子元素就是配置里写的名字）。
## 被谁用：UiSys._register_tree / find_name（拼登记名）、各处的警告文案。
var name: String = ""

## 背景图九宫格的边距**每张图各自给**：写在 config["background_slice"]（不写 = 0，整张拉伸）。
## 别用统一默认值——不同底图的圆角不一样，切多切少都会变形（见 _make_background）。
## "找当底的 stylebox 槽"的顺序放全局参数里：SysCfg.ui_background_slots（Config/SystemConfig.gd）。
## 本元素的配置（见 Config/UI/）。公共属性：position/size/content/children/events/visible/free，
## 各子类另有自己的（如菜单的 open_at / close_on_blur）。
## 被谁用：_apply_config、_build_children、on_event、UiSys._place（读 open_at）。
var config: Dictionary = {}
## 真正的引擎控件（本元素外观的根，子节点也挂在它下面）。
## 被谁用：UiSystem（挂载）、PointerDetect._ui_at（命中矩形）、UIInteract 各指令、UiSys._place。
var control: Control

## 显示内容：指明该 UI 展示什么（文本/多行文本/纹理路径…由子类解释）。
## 修改展示 = set_content(v)（内部自动 refresh），或改 content 后手动调 refresh()。
## 被谁用：_apply_config（从配置取）、子类 refresh（读）、UIInteract.set_content（指令写）。
var content: Variant = null

## 挂载对象（父 UI）：组装子元素时由父元素注入，即指令占位符 $parent 的指向。
## 被谁用：_build_children / add_child_element（注入）、_resolve_cmd（$parent 链）、
##         on_event（事件冒泡）、UIInteract_OpenClose._is_inside（判"指针是否在这个 UI 上"）。
var parent: UIBase = null

## 挂在 control 上的 meta 键：控件 → UIBase 反查（指针命中沿控件树走，见 PointerDetect._ui_at）。
## 被谁用：build()（写）、PointerDetect._hit_in（读）。
const META_UI := "ui_base"

## 子元素：build() 按 config["children"] 组装，每项 [child_name, ui_class, child_config]。
## 被谁用：_build_children / add_child_element（追加）、UiSys._register_tree（递归登记）、
##         _free_box 的选择依据（在 add_child_element 里读 free 配置）。
var children: Array[UIBase] = []


## 构造：只记名字与配置，控件在 build() 里才建。
## 被谁用：UIPreset.create_element（唯一的实例化工厂）→ UIPreset._get_ui_by_name。
func _init(name_: String = "", config_: Dictionary = {}) -> void:
	name = name_
	config = config_


## 生成控件树并组装子元素，返回 control（供 UiSystem 挂载）。
## 顺序不能换：建控件 → 应用配置 → 刷内容 → 建子元素 → 补尺寸（子元素建完才知道内容多大）。
## 建完把"我自己"挂在 control 的 meta 上（META_UI）：指针命中是**沿控件树**走的
## （见 PointerDetect._ui_at），走到一个没挂 meta 的内部控件（容器的 PanelContainer/VBox、
## 文本内部的 Label 之类）就往上取最近的这个元素。
## 被谁用：UIInteract_OpenClose._build_open（独立 UI 与寄主型都走它）、_build_children / add_child_element（子元素）。
func build() -> Control:
	control = _create_control()
	control.set_meta(META_UI, self)
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


## 对调 config 里两项的值（A ↔ B），如 `events` ↔ `events_2`、`content` ↔ `content_2`。
## 这就是"开关式按钮"的做法：**两套配置同时写在元素上**，点一下"做事 + 换一套配置"，
## 于是同一个元素（Label/Image/任意元素）在两次点击里走两套行为，不需要专门的开关元素。
## config 是"数据"，元素的界面状态是从运行时字段读的，所以换完必须同步镜像再刷新，否则界面不跟着变。
## 被谁用：UIInteract.swap_config（指令）。
func swap_config(key_a: String, key_b: String) -> void:
	if key_a == "" or key_b == "" or key_a == key_b:
		push_warning("UIBase「%s」.swap_config: 键名不合法（%s / %s）" % [name, key_a, key_b])
		return
	# 两套配置必须都写过：只写了一套时**什么都不做**（否则会把写了的那套换成 null，
	# 等于把 events 整个抹掉——那种"点了菜单项结果交互全没了"的坑很难查）。
	if not config.has(key_a) or not config.has(key_b):
		push_warning("UIBase「%s」.swap_config: %s / %s 没有成套写在 config 里，不切换"
			% [name, key_a, key_b])
		return
	var a: Variant = config.get(key_a)
	var b: Variant = config.get(key_b)
	config[key_a] = b
	config[key_b] = a
	_sync_from_config(key_a)
	_sync_from_config(key_b)
	refresh()


## 把 config 的某个键同步到对应的运行时字段（换配置后界面才会跟着变）。
## 目前是镜像关系的只有 content（显示内容）与 visible（可见性）；
## 以后再加"config 键 → 运行时字段"的镜像，记得也加进这里。
## 被谁用：swap_config。
func _sync_from_config(key: String) -> void:
	if key == "content":
		content = config.get("content")
	elif key == "visible" and control != null:
		control.visible = bool(config.get("visible", true))


## 摆到指定**屏幕坐标**并显示（按 open_at 策略开的 UI 用，见 UiSys._place）。
## 位置换算成"挂载点坐标系"的 position：
##   - 不用 set_global_position——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏；
##   - 也不设 Control.top_level——那会让元素不再继承父级可见性（父级 hide 后它还留在屏幕上、也还能被命中）。
## 被谁用：UiSys._place（POINTER / ANCHOR_TOP_RIGHT 两种策略）。
func show_at(pos: Vector2) -> void:
	if control == null:
		return
	var box: Control = control.get_parent() as Control
	var origin: Vector2 = box.get_global_rect().position if box != null else Vector2.ZERO
	control.position = pos - origin
	control.show()


## 摆回配置里声明的位置（config["position"]）；没配就不动。
## 被谁用：_apply_config（建时）、UiSys._place（CONFIG 策略：被拖动过的 UI 重开时回初值）。
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


## 应用 config 里的公共属性：position / size / content / visible / font_size / font_color / background。
## 被谁用：build()。子类覆写时必须先 super()（如 UI_Scroll 之后再调内层 label 的宽度）。
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
	# 字号/字色是通用属性（谁都能配），作用在**本元素的控件**上：
	# 主题重写只在配它的那个控件上生效，**不会自动传给子控件**——要小字号/深色字请配到真正显示文本的那个元素上。
	# （不配字色就用主题默认：Godot 默认主题是接近白色的，画在浅色底图上会看不见。）
	if config.has("font_size"):
		control.add_theme_font_size_override("font_size", int(config["font_size"]))
	if config.has("font_color"):
		var font_color: Color = config["font_color"]
		control.add_theme_color_override("font_color", font_color)
	_apply_background(str(config.get("background", "")))


## 虚接口 + 通用实现：给本元素铺一张背景图（config["background"] = 纹理路径）。
## 做法 = 给它**主题里那个"当底"的 stylebox 槽**套上九宫格图（槽名见 _background_slot）：
##   UI_Panel→panel（内层 PanelContainer）、UI_Label→normal、UI_Scroll→panel……
## 控件一个槽都没有（TextureRect / 纯 Control，本身不画 StyleBox）就画不出来：警告一次、不画。
## 那种元素要"带底"请换有槽的元素（文字带底 = UI_Panel 里放 UI_Label，键盘的键就是这么做的）。
## 被谁用：_apply_config。覆写者：UI_Panel（它要套在内层 _panel 上，不是根 Control）。
func _apply_background(path: String) -> void:
	var style: StyleBoxTexture = _make_background(path)
	if style == null:
		return
	var slot: String = _background_slot()
	if slot == "":
		push_warning("UIBase「%s」(%s): 控件没有可用的 stylebox 槽，画不出背景 %s"
			% [name, control.get_class() if control != null else "?", path])
		return
	control.add_theme_stylebox_override(slot, style)


## 本元素用哪个 stylebox 槽当底：按 SysCfg.ui_background_slots 取第一个存在的；一个都没有 → 空串。
## 被谁用：_apply_background。（UI_Panel 不走这里：它把图套在内层 PanelContainer 的 "panel" 上）
func _background_slot() -> String:
	if control == null:
		return ""
	for slot in SysCfg.ui_background_slots:
		if control.has_theme_stylebox(slot):
			return slot
	return ""


## 造一张九宫格背景样式（供 config["background"] 用）；路径为空/图片不存在/加载失败返回 null。
## 九宫格的边距取 config["background_slice"]（**每张图各自指定**，不写 = 0 = 整张拉伸）：
## 每张图的圆角半径不一样（Unity 那边每张 sprite 也自带自己的九宫格参数），所以要能逐个指定。
## 被谁用：_apply_background（本类与 UI_Panel 的覆写）。
func _make_background(path: String) -> StyleBoxTexture:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		push_warning("UIBase「%s」: 背景图不存在，改用默认样式：%s" % [name, path])
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = tex
	style.set_texture_margin_all(int(config.get("background_slice", 0)))  # 九宫格：圆角不被拉伸
	return style


## 组装子元素：config["children"] 每项 [child_name, ui_class, child_config]。
## 子元素的挂载对象（parent）即本元素（父 UI），其指令里的 $parent 指向本元素。
## 挂载点与运行时那条路**同一套规则**（见 add_child_element）：配了 free 的挂到叠加层
## （绝对定位，position/size 不被父级布局改），没配的进内容盒（容器类 = 竖排）。
## 被谁用：build()。（运行时加子元素走 add_child_element，那条路要额外登记。）
func _build_children() -> void:
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
		# free 的挂到叠加层（非容器，位置/尺寸保持配置值），否则进内容盒（竖排布局）
		var box: Control = _free_box() if bool(child_config.get("free", false)) else _content_box()
		box.add_child(child.control)


## 唯一事件入口（PointerDetect 派发）：参数是事件名——状态驱动的事件就是配置里的状态名
## （如 "Mouse Left"、"Mouse Left | Tick"；UI 不感知按键，键位只在状态层出现），
## hover 变化用 QName.pointer_enter / QName.pointer_exit。
## 事件→指令：在 config["events"]（[事件名, 指令串] 列表）里按等值取指令串，取到才发送。
## 自己没配的事件**冒泡给父级**：于是"整块面板的行为"在它的子元素上同样生效
## （如菜单面板启用拖拽后，按住菜单项也能拖；$self/$parent 以配了指令的那个元素为基准）。
## 冒泡到根仍没有配置就什么都不做（元素没有隐式行为）。
## 用列表而不是字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），
## 且要加新事件只需往列表里加一项。
## 占位符（$self/$parent 链/$event）由本类的 _resolve_cmd 解析——它是 on_event 的私有助手，
## 不挂在 UIInteract 的指令面上（没有第二个使用者）。
## 被谁用：PointerDetect.key（状态事件）、PointerDetect._process（enter/exit）、本函数自身（冒泡）。
func on_event(event_name: Variant) -> void:
	for entry in config.get("events", []):
		if not (entry is Array):
			push_warning("UIBase「%s」: config[\"events\"] 的项应为 [事件名, 指令串]，收到 %s" % [name, type_string(typeof(entry))])
			continue
		var pair: Array = entry
		if pair.size() >= 2 and pair[0] == event_name:
			var cmd: String = pair[1]
			Msg.send_cmd(_resolve_cmd(cmd, str(event_name)))
			return
	if parent != null:
		parent.on_event(event_name)


## 解析指令串占位符（发送前调用）：
##   $self   → 自身实例（$@ID）
##   $parent → 父 UI；$parent.parent → 祖父，链式任意级。级别不足时警告并用可达的最高级 parent 替代；
##             链尾若还跟着 ".xxx" 原样保留（成为 $@ID.xxx，指令系统会继续按表达式取该属性）。
##   $event  → 触发这次事件的**事件名**（= 状态名 / Key 名），**自带引号**——名字里通常有空格
##             （如 "Mouse Left"），指令要把整串当一个参数，所以这里补上引号；
##             于是配置可以写 `UIInteract.drag $parent $event`，不必把状态名再抄一遍。
## 被谁用：on_event（唯一调用方）。
func _resolve_cmd(cmd: String, event_name: String = "") -> String:
	cmd = cmd.replace("$self", "$@" + str(ID))
	if event_name != "":
		cmd = cmd.replace("$event", "\"" + event_name + "\"")
	var out := ""
	var i := 0
	while i < cmd.length():
		if cmd.substr(i, 7) == "$parent":
			var j := i + 7
			var levels := 1
			while cmd.substr(j, 7) == ".parent":
				levels += 1
				j += 7
			out += "$@" + str(_climb_parent(levels).ID)
			i = j
		else:
			out += cmd[i]
			i += 1
	return out


## 从自身沿 parent 向上爬 levels 级；不足时警告并返回可达的最高级。
## 被谁用：_resolve_cmd。
func _climb_parent(levels: int) -> UIBase:
	var cur: UIBase = self
	var climbed := 0
	for i in levels:
		if cur.parent == null:
			push_warning("UIBase「%s」只向上 %d 级 parent（配置请求 %d 级），用可达的最高级替代" % [name, climbed, levels])
			return cur
		cur = cur.parent
		climbed += 1
	return cur


## 运行时追加一个子元素（如菜单里后加的关闭按钮），返回新元素。
## 生成控件 → 挂到 _content_box()/_free_box() → 记进 children → 交给 UiSys 登记
## （登记后才可能被指针命中；登记名规则在 UiSys）。
## 登记名走 UiSys 唯一那条规则（`挂载点登记名/名字`），所以"开出来的 UI"与"配置里的子元素"命名一致。
## 被谁用：UIInteract_OpenClose._build_open（挂到宿主/锚点下的 UI）、UIInteract_OpenClose.close 的取件路径（_child_ui）。
func add_child_element(child_name: String, ui_class: String, child_config: Dictionary = {}) -> UIBase:
	var child: UIBase = UIPreset.create_element(child_name, ui_class, child_config)
	if child == null:
		return null
	child.parent = self
	child.build()
	children.append(child)
	# 配置里声明 free 的当"自由定位"元素：挂到叠加层，位置才不会被父级容器布局覆盖。
	# 注意不要给它设 Control.top_level——那样它就不再继承父级可见性，宿主关了它还会留在屏幕上；
	# 摆放时把屏幕坐标换算成挂载点坐标系的 position 即可（见 UiSys._place）。
	var box: Control = _free_box() if bool(child_config.get("free", false)) else _content_box()
	box.add_child(child.control)
	UiSys.register_child(self, child)
	return child
