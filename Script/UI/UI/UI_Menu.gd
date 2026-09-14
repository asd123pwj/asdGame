class_name UI_Menu
extends UI_Panel
## 菜单 UI（设计见 Script/UI/UI.md）。和 UI_Label / UI_Scroll / UI_Image 一样是 UIBase 子类，
## 只是配置多几条：菜单项就是它 config["children"] 里的子 UI，行为由子 UI 的事件绑定给出。
##
## **菜单是宿主 UI 的子元素**（由 UiSystem.open_ui 现场创建、挂到宿主下），所以：
##   菜单项的 $parent        = 菜单（本元素）
##   菜单项的 $parent.parent = 宿主 UI  ← 菜单项的功能都作用于宿主
## 即：菜单只是"快捷方式"，"关闭/添加关闭按钮/启用拖拽"操作的都是宿主那个 UI，
## 就像右键窗口标题栏点"关闭"关掉的是窗口，而不是菜单。
## 因为菜单是宿主的子元素（且**不设 Control.top_level**，可见性照常继承），宿主一 hide 菜单随之不可见，
## 也不再参与指针命中。
##
## config 额外字段：
##   open_at:       Enums.OpenAt  开启位置策略（POINTER = 指针处 / ANCHOR_TOP_RIGHT = 锚点右上角）
##   close_on_blur: bool          失焦关闭——按键时指针不在本菜单链上就关掉自己（隐藏，连同子菜单）
##   free:          bool          自由定位（挂到宿主叠加层，位置不被父级容器布局覆盖）——菜单应开
##   children:                    菜单项（普通子 UI；事件绑定里用 $parent.parent 指宿主）
##
## 生命周期：**关闭 = 隐藏**，实例留在宿主下复用（UiSystem.open_ui 找到就直接显示并挪位置）；
## 同一 (宿主, 预设) 只有一份，隐藏的实例不参与指针命中、也不算"开着"。

## 现存的菜单实例：给"同一宿主 + 同一预设只留一份"（find_instance）与失焦关闭（notify_key_event）用。
## 被谁用：_apply_config（追加）、find_instance / has_any_open / notify_key_event（遍历）。
static var _instances: Array[UI_Menu] = []

## 由哪个预设开的（UiSystem._build_open 填），用于判断"同一宿主 + 同一预设"。
## 被谁用：find_instance。
var preset_name: String = ""
## 失焦关闭开关（来自 config["close_on_blur"]）。
## 被谁用：notify_key_event（决定要不要关自己）。
var close_on_blur: bool = false
## 弹出本菜单的那一级菜单 / 从本菜单弹出的子菜单（由 UiSystem._build_open 按 anchor 记）。
## 被谁用：close_self（整链一起关）。
var parent_menu: UI_Menu = null
## 见 parent_menu 的说明。
var child_menus: Array[UI_Menu] = []


## 记配置 + 把自己登记进 _instances（登记后才会被"复用查找/失焦关闭"看到）。
## 被谁用：UIBase.build()（建元素时）。
func _apply_config() -> void:
	super()
	close_on_blur = bool(config.get("close_on_blur", false))
	if not _instances.has(self):
		_instances.append(self)


## 关掉自己（recursive 时连同自己弹出的子菜单）：**只隐藏，不销毁**。
## 实例留在宿主下，下一次 UiSystem.open_ui 找到它就直接显示并挪到新位置。
## 父子菜单的相互登记保留着，所以重新打开后再关，仍然能整链一起关。
## 被谁用：notify_key_event（失焦关闭）。
func close_self(recursive: bool = true) -> void:
	if control != null:
		control.hide()
	if recursive:
		for m: UI_Menu in child_menus.duplicate():
			if is_instance_valid(m):
				m.close_self(true)


## 找"同一宿主 + 同一预设"已存在的菜单（顺手清掉失效项）；没有返回 null。
## 被谁用：UiSystem._find_open（开启时的复用查找）。
static func find_instance(host: UIBase, preset: String) -> UI_Menu:
	for m: UI_Menu in _instances.duplicate():
		if not is_instance_valid(m) or m.control == null:
			_instances.erase(m)
			continue
		if m.parent == host and m.preset_name == preset:
			return m
	return null


## 从 ui 沿 parent 链向上找最近的菜单（用于把子菜单记到"弹出它的那一级"上）。
## 被谁用：UiSystem._build_open（anchor → 弹出它的那一级菜单）。
static func nearest(ui: UIBase) -> UI_Menu:
	var cur: UIBase = ui
	while cur != null:
		if cur is UI_Menu:
			return cur
		cur = cur.parent
	return null


## 是否有菜单正开着（隐藏的不算）。
## 被谁用：PointerDetect.key（先判有没有菜单，再决定要不要跑失焦检查）。
static func has_any_open() -> bool:
	for m: UI_Menu in _instances.duplicate():
		if not is_instance_valid(m) or m.control == null:
			_instances.erase(m)
			continue
		if m.control.is_visible_in_tree():
			return true
	return false


## 按键后调用：失焦关闭——指针不在某菜单链上就关掉它（连同子菜单）。
## hover_ui 由调用方用**当前指针位置**刷新后传入（菜单可能是刚在指针处打开的，旧的 hover 会误判）。
## 被谁用：PointerDetect.key。
static func notify_key_event(hover_ui: UIBase) -> void:
	for m: UI_Menu in _instances.duplicate():
		if not is_instance_valid(m) or m.control == null:
			_instances.erase(m)
			continue
		if not m.close_on_blur or not m.control.is_visible_in_tree():
			continue
		if not _is_inside(m, hover_ui):
			m.close_self(true)


## hover 是否在 menu 这条链上：沿 parent 链向上找，碰到 menu 即为"内"。
## 只往上找，所以宿主 UI 不算菜单内（链到宿主之前会先碰到菜单本身）。
## 被谁用：notify_key_event。
static func _is_inside(menu: UI_Menu, hover_ui: UIBase) -> bool:
	var cur: UIBase = hover_ui
	while cur != null:
		if cur == menu:
			return true
		cur = cur.parent
	return false
