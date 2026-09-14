class_name UiSystem
extends BaseClass
## UI 管理脚本（设计见 Script/UI/UI.md）。
## 职责：UI 的**开启与登记**——全项目唯一的开启入口 `open_ui()` 在本类，
## 普通 UI（挂 UI 根）与菜单/提示（挂宿主下）走同一条路，区别只在参数与被开启 UI 自己的配置。
## 交互（关闭/拖动/渐隐/改内容）在 UIInteract 静态类，元素按事件发指令驱动。

## UI 根（CanvasLayer）：所有"没有宿主"的 UI 都挂这里。
## 被谁用：_init（创建）、_build_open（挂独立 UI）。
var root: CanvasLayer
## 已登记的 UI：key = 登记名（独立 UI 用预设名，如 "MiniHUD"；子元素用 "根名/子名"，如 "MiniHUD/Info"）。
## 被谁用：PointerDetect._ui_at（指针命中）、_find_open（复用查找）、get_ui（外部按名取）。
var uis: Dictionary[String, UIBase] = {}


func _init() -> void:
	root = CanvasLayer.new()
	root.name = "UIRoot"
	# 初始化发生在 Sys._ready()（引擎仍在建子节点），需延迟到本帧空闲再挂载
	Sys.sys.get_tree().root.add_child.call_deferred(root)


## 开启一个 UI —— **全项目唯一的开启入口**（不要再写第二个，普通 UI 与菜单都走这里）。
## 被谁用：UIInteract.open_ui（配置指令的唯一入口）、Test.ui_test（测试）。
##   preset_name = 预设名（见 Config/UI/）
##   host        = 宿主。给了就挂到它下面（菜单/提示这类"寄主型"UI：它的子元素里
##                 $parent.parent 指回宿主）；不给（null）就挂到 UI 根（独立面板）。
##   anchor      = 位置锚点，只给需要锚点的 open_at 策略用（多级菜单传触发它的那个菜单项）
## 复用规则：同一目标已存在时**只显示 + 重新摆位**，不重建控件——独立 UI 按预设名找（uis），
##           寄主型按"同一宿主 + 同一预设"找（UI_Menu.find_instance）。
## 返回：开出来的 UI（找不到预设/建不出来为 null）。
func open_ui(preset_name: String, host: UIBase = null, anchor: UIBase = null) -> UIBase:
	var preset: UIPreset = UIPreset.get_(preset_name)
	if preset == null or preset.ui_name == "":
		push_warning("UiSystem.open_ui: 找不到预设「%s」（见 Config/UI/）" % preset_name)
		return null
	var ui: UIBase = _find_open(host, preset_name)
	if ui == null:
		ui = _build_open(preset, preset_name, host, anchor)
	if ui == null:
		return null
	_place(ui, anchor)
	return ui


## 取一个已登记的 UI（子元素用全名，如 "MiniHUD/Info"）。
## 被谁用：Test.ui_test（拿滚动区改内容）、外部按名取子元素。
func get_ui(name: String) -> UIBase:
	return uis.get(name)


## 给已登记的 UI 追加一个子元素并登记（由 UIBase.add_child_element 调用）。
## 登记后才可能被指针命中；父元素没登记就警告（子元素会永远收不到事件）。
## 被谁用：UIBase.add_child_element（运行时加子元素，如菜单的"添加关闭按钮"）。
func register_child(parent: UIBase, child: UIBase) -> void:
	var parent_name: String = find_name(parent)
	if parent_name == "":
		push_warning("UiSystem: 追加子元素「%s」时父元素未登记，该元素无法被指针命中" % child.name)
		return
	_register_tree(child, parent_name + "/" + child.name)


## 反查一个已登记 UI 的登记名（未登记返回空串）。
## 被谁用：register_child（拼子元素的登记名）。
func find_name(ui: UIBase) -> String:
	for key in uis:
		if uis[key] == ui:
			return key
	return ""


## 复用查找：该开启目标是否已经在？独立 UI 按预设名，寄主型按"同一宿主 + 同一预设"。
## 被谁用：open_ui。
func _find_open(host: UIBase, preset_name: String) -> UIBase:
	if host == null:
		return uis.get(preset_name)
	return UI_Menu.find_instance(host, preset_name)


## 现场造一个开启目标并登记：host 为空 → 建预设自己那份挂 UI 根；有 host → 挂到宿主下。
## 寄主型用**深拷贝模板**（各实例互不影响："加按钮/加绑定"只改自己这一份）。
## 被谁用：open_ui。
func _build_open(preset: UIPreset, preset_name: String, host: UIBase, anchor: UIBase) -> UIBase:
	if host == null:
		var ui: UIBase = preset.ui
		root.add_child(ui.build())
		_register_tree(ui, preset_name)
		Msg.send_ui_create(ui)
		return ui
	var child: UIBase = host.add_child_element(preset_name, preset.ui_name, preset.config.duplicate(true))
	if child == null:
		return null
	var menu := child as UI_Menu
	if menu != null:
		menu.preset_name = preset_name
		# 子菜单记到"弹出它的那一级菜单"上：那一级关闭时整链一起关
		var opener: UI_Menu = UI_Menu.nearest(anchor)
		if opener != null and opener != menu:
			menu.parent_menu = opener
			if not opener.child_menus.has(menu):
				opener.child_menus.append(menu)
	return child


## 按被开启 UI 自己的 config["open_at"] 摆位置并显示（Enums.OpenAt）：
##   CONFIG（默认，不写就是它）→ 摆回配置声明的 position（独立面板；被拖动过就回到初值）
##   POINTER                   → 开在指针处（右键菜单，anchor 用不上，随便传一个）
##   ANCHOR_TOP_RIGHT          → 开在 anchor 的右上角顶点（多级菜单传触发它的那个菜单项）
## 被谁用：open_ui。
func _place(ui: UIBase, anchor: UIBase) -> void:
	if ui.control == null:
		return
	var strategy: int = int(ui.config.get("open_at", Enums.OpenAt.CONFIG))
	if strategy == Enums.OpenAt.POINTER:
		ui.show_at(InputSys.mouse_position)
	elif strategy == Enums.OpenAt.ANCHOR_TOP_RIGHT:
		if anchor != null and anchor.control != null:
			var rect: Rect2 = anchor.control.get_global_rect()
			ui.show_at(Vector2(rect.end.x, rect.position.y))
		else:
			push_warning("UiSystem.open_ui: 「%s」要求开在锚点右上角，但锚点不可用，改在指针处开" % ui.name)
			ui.show_at(InputSys.mouse_position)
	else:
		ui.reset_position()
		ui.control.show()


## 登记整棵 UI 树：根用原名，子元素用 "根名/子名"。
## 子元素也进 uis，PointerDetect 才能把指针命中派发到具体子元素（如关闭按钮、菜单项）。
## 被谁用：_build_open（独立 UI）、register_child（运行时子元素）。
func _register_tree(ui: UIBase, full_name: String) -> void:
	uis[full_name] = ui
	for child in ui.children:
		_register_tree(child, full_name + "/" + child.name)
