class_name UI_Panel
extends UIBase
## 面板容器：自身只是外观 + 竖排布局，功能（标题/关闭按钮/滚动内容…）
## 全部由 config["children"] 声明的子元素组装（见 Script/UI/UI.md）。
## 结构（内部节点都起了名，编辑器里看树一眼能认）：
##   root(Control，本元素的 control) → Panel → Margin → Box(VBoxContainer，普通子元素挂这里)
##                                   └→ Overlay(Control)：free 子的自由定位挂载点
## 配了 `config["scroll"] = [上限宽, 上限高]`（0 = 该维不限制）时，中间多一层 ScrollContainer：
##   … → Margin → Scroller → Box；面板尺寸按"**内容需要 ↔ 上限**"取小 ⇒ 内容一多就进去滚动、
##   不再顶着屏幕往下长（UI 编辑器那种"内容长短不定"的就是它）。见 UI.md 的"面板滚动"。

## 面板边距（_create_control 给 MarginContainer 的那四个常量；算"内容需要多大"时要加上）。
const MARGIN_SIZE := Vector2(16, 12)

## 内层面板（真正的容器：含边距 + 内容）。
## 被谁用：_create_control（建）、_content_size（问内容多大）。
var _panel: PanelContainer
## 子元素的挂载点（竖排布局）。
## 被谁用：_create_control（建）、_content_box。
var _box: VBoxContainer
## free 子元素的挂载点（非容器，position 不会被布局覆盖）。
## 被谁用：_create_control（建）、_free_box。
var _overlay: Control
## 滚动容器：**只在配了 config["scroll"] 时才建**（没配就是 null，布局与以前完全一样）。
## 被谁用：_create_control（建）、_content_size（滚动模式下按上限收口）。
var _scroll: ScrollContainer


## 建控件树：外层普通 Control（position/size 由配置决定，绝对定位的子元素也挂在它下面）
## + 全铺的内层面板 + 内容盒 + 叠加层。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	var root: Control = Control.new()
	root.name = name

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 内容最小尺寸一变就重算根尺寸：建时还没进树、字体主题都问不出来，
	# 内容多大要等容器排完版才知道。size 里为 0 的那一维就靠这里补，
	# 否则会停在 0——高度 0 的矩形 get_global_rect() 永远命中不到（见 UIBase._content_size）。
	_panel.minimum_size_changed.connect(_fit_size)
	root.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", int(MARGIN_SIZE.x / 2.0))
	margin.add_theme_constant_override("margin_right", int(MARGIN_SIZE.x / 2.0))
	margin.add_theme_constant_override("margin_top", int(MARGIN_SIZE.y / 2.0))
	margin.add_theme_constant_override("margin_bottom", int(MARGIN_SIZE.y / 2.0))
	_panel.add_child(margin)

	# 配了 scroll 就多一层滚动容器：内容多了进去上下滚。横向**关掉**——让子元素按视口宽度排
	# （长文本自己在框里换行，不用横向拖）。
	if config.has("scroll"):
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroller"
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(_scroll)

	_box = VBoxContainer.new()
	_box.name = "Box"
	# 子元素最小尺寸一变就重算面板尺寸：滚动模式下"内容需要多大"只能问内容盒
	# （有 ScrollContainer 时 _panel 报的是滚动容器的最小尺寸，跟内容无关，见 _content_size）。
	_box.minimum_size_changed.connect(_fit_size)
	(_scroll if _scroll != null else margin).add_child(_box)

	# 叠加层：给"自由定位"的子元素（关闭按钮、菜单）用——它不是容器，position/size 不会被布局覆盖
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_overlay)
	return root


## 子元素挂到内部竖排容器。
## 被谁用：UIBase._build_children / add_child_element / _free_box（默认值）。
func _content_box() -> Control:
	return _box


## 自由定位的子元素挂到叠加层（见 UIBase.add_child_element 与 _build_children 的 free 分支）。
## 被谁用：UIBase.add_child_element、UIBase._build_children。
func _free_box() -> Control:
	return _overlay


## 内容最小尺寸要问内部面板：根 Control 是普通 Control，不会汇总子元素的最小尺寸，
## 直接问它只会得到"配置里写的那点值"，[宽, 0] 就会变成高度 0 的退化矩形（画不出来也命中不到）。
## _panel 是真正的容器（含边距 + 内容），它才报得出内容需要多大。
## **滚动模式**（config["scroll"]）改问**内容盒**并按上限收口：面板最多长到上限，多出来的进去滚动
## ——所以"内容很长"不再是问题，也不会顶出屏幕（见文件头）。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	if _scroll == null:
		return _panel.get_combined_minimum_size()
	var need: Vector2 = _box.get_combined_minimum_size() + MARGIN_SIZE
	var cap: Vector2 = _scroll_cap()
	if cap.x > 0.0:
		need.x = minf(need.x, cap.x)
	if cap.y > 0.0:
		need.y = minf(need.y, cap.y)
	return need


## config["scroll"] 的上限（[宽, 高]，0 = 该维不限制）。没配 / 写得不全 = (0, 0) = 不限制。
## 被谁用：_content_size。
func _scroll_cap() -> Vector2:
	var s: Variant = config.get("scroll")
	if not (s is Array):
		return Vector2.ZERO
	var arr: Array = s
	if arr.size() >= 2:
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2.ZERO


## 把 config["background"] 的图做成九宫格面板底。
## 覆写基类：底要套在**内层 PanelContainer**（_panel）的 "panel" 上——本元素的根控件是普通 Control，
## 它自己不画 StyleBox，套在它身上什么也看不见。
## 有了它整块面板就能用一张图当底（键盘 UI 那种），子元素照常画在上面——
## 不用专门放个 Image 元素当背景：Image 属于"内容"，摆在叠加层上会盖住其它子元素。
## 被谁用：UIBase._apply_config。
func _apply_background(path: String) -> void:
	var style: StyleBoxTexture = _make_background(path)
	if style == null:
		return
	_panel.add_theme_stylebox_override("panel", style)
