class_name UI_Panel
extends UIBase
## 面板容器：自身只是外观 + 竖排布局，功能（标题/关闭按钮/滚动内容…）
## 全部由 config["children"] 声明的子元素组装（见 Script/UI/UI.md）。
## 结构（内部节点都起了名，编辑器里看树一眼能认）：
##   root(Control，本元素的 control) → Panel → Margin → Box(VBoxContainer，普通子元素挂这里)
##                                   └→ Overlay(Control)：free 子的自由定位挂载点
## **内容外面总有一层 ScrollContainer**（… → Margin → Scroller → Box）⇒ "装不下"永远是滚动条，不画到面板外：
##   · 面板尺寸**由内容定**（size 那一维写 0）⇒ 面板长到刚好装下，滚动条不出现；
##   · 面板尺寸**由面板定**（size 写了数 / 拖手柄改小过）⇒ 内容超出去就在框内滚动
##     ——竖向滚动条是 ScrollContainer 自动出的，不用配什么；
##   · `config["scroll"] = [上限宽, 上限高]`（0 = 该维不限制）= "**面板最多长到这儿**"：内容再多也进去滚动、
##     不再顶着屏幕往下长（UI 编辑器那种"内容长短不定"的就是它）。见 UI.md 的"面板滚动"。

## 面板边距（_create_control 给 MarginContainer 的那四个常量；算"内容需要多大"时要加上）。
## 16 ⇒ 四边各 8。别调太大：面板总高 = 内容 + 它，段与段之间就靠它留白，
## 一大就"两块东西隔老远"（实测踩过）。
const MARGIN_SIZE := Vector2(16, 16)

## 内层面板（真正的容器：含边距 + 内容）。
## 被谁用：_create_control（建）、_content_size（问内容多大）。
var _panel: PanelContainer
## 子元素的挂载点（竖排布局）。
## 被谁用：_create_control（建）、_content_box。
var _box: VBoxContainer
## free 子元素的挂载点（非容器，position 不会被布局覆盖）。
## 被谁用：_create_control（建）、_free_box。
var _overlay: Control
## 四角的"自动排位"容器（角 → HBoxContainer，按需建，见 `_corner_box`）。
## 被谁用：_corner_box。
var _corners: Dictionary = {}


## 建控件树：外层普通 Control（position/size 由配置决定，绝对定位的子元素也挂在它下面）
## + 全铺的内层面板 + 内容盒 + 叠加层。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	var root: Control = Control.new()
	root.name = name
	# **不裁画面**（root.clip_contents 保持 false）：浮窗、子菜单这类"挂在面板里、却要画到面板外"的
	# UI 全靠越出面板矩形——裁了它们就整个被裁没（实测：浮窗只露出约 24px 的一条边，看着就是
	# "开不出来"，指针事件其实都好好走着）。当初加裁剪防的是"固定宽面板装不下长文案、画出去的
	# 部分点在面板外也命中"——那个前提已经没了：现在面板宽随内容走（见 UI.md 的"面板宽度"），
	# 画出去的东西不存在；滚动内容由滚动容器自己裁，不靠这里。
	# （`PointerDetect._hit_in` 认 `clip_contents` 跳过的逻辑仍在：滚动容器那类显式裁剪照常生效。）

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 内容最小尺寸一变就重算根尺寸：建时还没进树、字体主题都问不出来，
	# 内容多大要等容器排完版才知道。size 里为 0 的那一维就靠这里补，
	# 否则会停在 0——高度 0 的矩形 get_global_rect() 永远命中不到（见 UIBase._content_size）。
	# （内容那边的变化由下面 `_box` 那条信号负责：面板里隔着滚动容器，问 _panel 问不出内容多大。）
	_panel.minimum_size_changed.connect(_fit_size)
	root.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	var pad: Vector2 = _margin()                     # 四边各多少（config["margin"] 可覆盖默认 8）
	margin.add_theme_constant_override("margin_left", int(pad.x))
	margin.add_theme_constant_override("margin_right", int(pad.x))
	margin.add_theme_constant_override("margin_top", int(pad.y))
	margin.add_theme_constant_override("margin_bottom", int(pad.y))
	_panel.add_child(margin)

	# 内容外面**总是**包一层滚动容器：横向关掉（让子元素按视口宽度排，长文本自己在框里换行、不用横向拖），
	# 竖向自动（装得下就不出现、装不下才出滚动条）——面板尺寸定死、或拖手柄改小时，
	# 超出的内容进去滚动，而不是画到面板外面（见文件头）。
	# 不必存成成员：建完就交给引擎自己滚（滚到哪由用户操作），面板尺寸靠下面 `_box` 那条信号跟。
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Scroller"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_box = VBoxContainer.new()
	_box.name = "Box"
	# **横向撑满视口**：ScrollContainer 只把子节点排到"它自己的最小尺寸"，不负责拉宽——不写这一句，
	# Box 就停在最小宽度，而折行文本的最小宽度是 0/1px ⇒ **里面的文字被压成一列**
	# （实测：320 宽的面板里正文只有 1px 宽、折成 74 行）。竖向**不写**：高度要按内容来，
	# 高于视口时才由滚动容器出滚动条。
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# **行间距归零**：竖排默认 separation = 4 ⇒ "两行"会变成 32+32+4 = 68（超过网格的 64）。
	# 行自己的高度里已经有富余（32 装 28 的字 ⇒ 上下各 2px），不靠容器的间隔留白。
	_box.add_theme_constant_override("separation", 0)
	# 子元素最小尺寸一变就重算面板尺寸：内容多大只能问内容盒
	# （滚动容器的最小尺寸恒为 0，隔着它问 _panel 问不出内容多大，见 _content_size）。
	_box.minimum_size_changed.connect(_fit_size)
	scroll.add_child(_box)

	# 叠加层：给"自由定位"的子元素（关闭按钮、菜单）用——它不是容器，position/size 不会被布局覆盖
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_overlay)
	return root


## 面板内边距（**四边各多少**）：`config["margin"]` 可覆盖默认值，一个数（四边都这么多）
## 或 `[横向, 纵向]`；不写 = 四边各 8（= `MARGIN_SIZE` 的一半）。
## 想"内容离边框更远/更近"就写它，**别去改 `MARGIN_SIZE` 那个常量**（它是全项目默认值）。
## 被谁用：_create_control（给 MarginContainer）、_content_size（算"内容需要多大"时要加上）。
func _margin() -> Vector2:
	var m: Variant = config.get("margin")
	if m is Array and (m as Array).size() >= 2:
		return Vector2(float(m[0]), float(m[1]))
	if m is float or m is int:
		return Vector2(float(m), float(m))
	return MARGIN_SIZE / 2.0


## 同一角上多个图标之间的间隔（角落容器里）。
const CORNER_GAP := 4


## 四角的"自动排位"容器（按需建）：同一个角上放多个图标（关闭 / 缩放 / 改尺寸…）时自己排成一行，
## **不用手算坐标**、也就不用跟着面板尺寸变来变去（锚点由引擎维护，面板缩放/改尺寸都自动跟）。
## 整行**贴着右边缘**，尺寸变大时**往左长**（`grow_horizontal = BEGIN`）⇒ 角上那个（最先加的）位置不动。
## 只做"内部右上 / 内部右下"两种（与 `UIBase._anchor_free_child` 认的一致）；其余 open_at 是"开在屏幕某处"，
## 那是 open 的事（见 UIInteract_OpenClose._place）。
## 被谁用：UIBase._attach_child_control。
func _corner_box(at: int) -> Control:
	var top_right: bool = at == Enums.OpenAt.ANCHOR_TOP_RIGHT_IN
	var bottom_right: bool = at == Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN
	if not (top_right or bottom_right):
		return null
	if _corners.has(at):
		return _corners[at]
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "CornerTopRight" if top_right else "CornerBottomRight"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE             # 只负责排位，不参与命中
	row.add_theme_constant_override("separation", CORNER_GAP)
	row.alignment = BoxContainer.ALIGNMENT_END                 # 整行贴着右边缘
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN         # 尺寸变了往左长（右边缘不动）
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if top_right else Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE)
	_overlay.add_child(row)
	_corners[at] = row
	return row


## 子元素挂到内部竖排容器。
## 被谁用：UIBase._build_children / add_child_element / _free_box（默认值）。
func _content_box() -> Control:
	return _box


## 让内边距跟着 config 走：`margin` 是布局项（`_create_control` 建的时候就套上了），
## 运行时改了要**重刷一次**才生效（`@self.reapply()`；重开这个 UI 也会走到）。
## 被谁用：UIBase.build()、配置里改完布局项紧跟的 `@self.reapply()`。
func reapply() -> void:
	super.reapply()
	if _panel == null:
		return                       # 控件还没建（异常路径）：没有内边距可套
	var margin: MarginContainer = _panel.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		return
	var pad: Vector2 = _margin()
	margin.add_theme_constant_override("margin_left", int(pad.x))
	margin.add_theme_constant_override("margin_right", int(pad.x))
	margin.add_theme_constant_override("margin_top", int(pad.y))
	margin.add_theme_constant_override("margin_bottom", int(pad.y))


## 自由定位的子元素挂到叠加层（见 UIBase.add_child_element 与 _build_children 的 free 分支）。
## 被谁用：UIBase.add_child_element、UIBase._build_children。
func _free_box() -> Control:
	return _overlay


## 叠加层公布给"往上找挂载点"的子孙元素（如挂在文本上的浮窗：文本自己有裁剪、滚动区也裁，
## 只有挂到这一层才画得出去，见 UIBase._free_box）。
func _own_free_layer() -> Control:
	return _overlay


## 内容需要多大：**问内容盒**（装内容那个竖排容器）+ 内边距。
## **不能问 `_panel`**：根 Control 是普通 Control 不汇总子元素（问它只得到"配置里写的那点值"，
## [宽, 0] 就成了高度 0 的退化矩形、画不出来也命中不到）；而 `_panel` 里隔着 ScrollContainer，
## 滚动容器的最小尺寸恒为 0 ⇒ 问它只会得到"边距那么大"，内容等于没了。
## **底图（StyleBox）自己也有最小尺寸**（九宫格边距）：面板整体不能比它小，所以取两者大的那个。
## `config["scroll"]` 的上限在这里收口：内容再多面板也只长到上限，多出来的进去滚动（见文件头）。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	var need: Vector2 = _box.get_combined_minimum_size() + _margin() * 2.0
	need = need.max(_panel.get_combined_minimum_size())
	var cap: Vector2 = _scroll_cap()
	if cap.x > 0.0:
		need.x = minf(need.x, cap.x)
	if cap.y > 0.0:
		need.y = minf(need.y, cap.y)
	return need


## config["scroll"] 的上限（[宽, 高]，0 = 该维不限制）。没配 / 写得不全 = (0, 0) = 不限制。
## **宽度写 0 就是"宽跟着内容走"**（长文案才不会被裁，见 UI.md 的"面板宽度"）；
## 高度写个数就是"最多长这么高，再多进去滚动"。
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
