class_name UI_Panel
extends UIBase
## 面板容器：自身只是外观 + 竖排布局，功能（标题/关闭按钮/滚动内容…）
## 全部由 config["children"] 声明的子元素组装（见 Script/UI/UI.md）。
## 结构：root(Control，本元素的 control) → PanelContainer → MarginContainer → VBoxContainer（子元素挂这里）
##                                     └→ _overlay(Control)：free 子的自由定位挂载点

## 内层面板（真正的容器：含边距 + 内容）。
## 被谁用：_create_control（建）、_content_size（问内容多大）。
var _panel: PanelContainer
## 子元素的挂载点（竖排布局）。
## 被谁用：_create_control（建）、_content_box。
var _box: VBoxContainer
## free 子元素的挂载点（非容器，position 不会被布局覆盖）。
## 被谁用：_create_control（建）、_free_box。
var _overlay: Control


## 建控件树：外层普通 Control（position/size 由配置决定，绝对定位的子元素也挂在它下面）
## + 全铺的内层面板 + 内容盒 + 叠加层。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	var root: Control = Control.new()
	root.name = name

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 内容最小尺寸一变就重算根尺寸：建时还没进树、字体主题都问不出来，
	# 内容多大要等容器排完版才知道。size 里为 0 的那一维就靠这里补，
	# 否则会停在 0——高度 0 的矩形 get_global_rect() 永远命中不到（见 UIBase._content_size）。
	_panel.minimum_size_changed.connect(_fit_size)
	root.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	_box = VBoxContainer.new()
	margin.add_child(_box)

	# 叠加层：给"自由定位"的子元素（关闭按钮、菜单）用——它不是容器，position/size 不会被布局覆盖
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_overlay)
	return root


## 子元素挂到内部竖排容器。
## 被谁用：UIBase._build_children / add_child_element / _free_box（默认值）。
func _content_box() -> Control:
	return _box


## 自由定位的子元素挂到叠加层（见 UIBase.add_child_element 的 free 分支）。
## 被谁用：UIBase.add_child_element。
func _free_box() -> Control:
	return _overlay


## 内容最小尺寸要问内部面板：根 Control 是普通 Control，不会汇总子元素的最小尺寸，
## 直接问它只会得到"配置里写的那点值"，[宽, 0] 就会变成高度 0 的退化矩形（画不出来也命中不到）。
## _panel 是真正的容器（含边距 + 内容），它才报得出内容需要多大。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	return _panel.get_combined_minimum_size()
