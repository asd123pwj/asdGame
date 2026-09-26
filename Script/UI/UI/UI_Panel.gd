class_name UI_Panel
extends UIBase
## 面板容器：自身只是外观 + 竖排布局，功能（标题/关闭按钮/滚动内容…）
## 全部由 config["children"] 声明的子元素组装（见 Script/UI/UI.md）。
## 结构（内部节点都起了名，编辑器里看树一眼能认）：
##   root(Control，本元素的 control) → Panel → Margin → Box(VBoxContainer，普通子元素挂这里)
##                                   │                      └→ Grid(Control)：**网格模式才建**，网格区
##                                   └→ Overlay(Control)：free 子的自由定位挂载点
## **子元素怎么排，看 config**（都在 `_layout_grid` 里分派）：
##   · 不写      ⇒ 竖排（VBoxContainer）：一个接一个往下堆；
##   · `matrix`  ⇒ 二维矩阵网格：**同一个编号出现几格 = 该元素跨几格 / 跨几行**，进网格的子元素写
##                  `grid: 编号`；面板尺寸一变，格子按比例跟着缩放 ⇒ 拖"改尺寸"手柄排版不变（见 `_layout_matrix`）；
##   · `cell`    ⇒ 等大格子网格（背包那种）：格子等大、**列数随内容区宽度变**，不够一格的余量摊进间距
##                  （撑到能多塞一列就换行）；排不下时内容盒撑高 ⇒ 面板出滚动条（见 `_layout_uniform`）。
## **网格面板照样能带普通子元素**：写了 `grid` 的进网格区；**没写的留在竖排里、排在网格上方**
## （可折叠标题、一行说明都放这儿）。所以网格区是竖排容器里"占剩下高度"的那个子节点（`_grid_box`）。
## （网格面板的尺寸要**定死**——`size`，或用手柄拖：格子按"网格区现在多大"算，
##   没有"内容需要多大"可言；不写的话网格区只剩标题那么高。）
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
## 普通子元素的挂载点：**永远是 VBoxContainer**（竖排；网格模式下网格区也排在它里面，见 `_grid_box`）。
## 被谁用：_create_control（建）、_content_box、_content_size、_attach_child_control。
var _box: Control
## **网格区**（配了 `matrix` / `cell` 才建）：普通 Control，占竖排里剩下的高度，格子都挂它下面——
## 子元素的 position/size 由 `_layout_grid` 按矩阵 / 等大格子自己算（它不做任何布局）。
## 单独立一个而不是直接用 `_box`：这样网格上方还能有一行标题（见文件头）。
## 被谁用：_create_control（建）、_attach_child_control（格子挂这儿）、_layout_matrix / _layout_uniform。
var _grid_box: Control
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
	# 采样模式：**全项目统一最近邻**（像素风、放大不糊），一处生效——
	# `project.godot` 的 `rendering/textures/canvas_textures/default_texture_filter=0`。
	# 所以这里不再逐个控件指定 texture_filter（原来分过"图像最近邻 / 文字线性"两层，见 UI.md）。
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
	# **嵌套面板（网格格/段，`parent` 是 `UI_Panel`）的竖向滚动条常驻**：嵌套空间小、内容几乎总比
	# 可视区高，滚动条几乎常在；而且"内容最小高"会随可用宽变（折行文本宽了行就少）——若滚动条
	# 出现/消失，可视区宽跟着变 8px，折行数跟着变，内容高又跟着变…… **双稳态帧间振荡**（RichText
	# 的折行高还是异步更新的，永远差一拍）⇒ 排版永不收敛，最终把引擎排版队列压崩 = 开着看板就
	# signal 11 闪退（实测：角色看板三格布局，段标题在 1 行/2 行之间无限横跳）。常驻滚动条把可视区
	# 宽钉死，反馈链斩断。顶层窗口保持 AUTO（装得下就不出滚动条，不糟蹋视觉）。
	if parent is UI_Panel:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	margin.add_child(scroll)

	# 内容盒：**永远是竖排**（网格模式下"网格区"也排在它里面，见文件头那一节）。
	_box = VBoxContainer.new()
	# **行间距归零**：竖排默认 separation = 4 ⇒ "两行"会变成 32+32+4 = 68（超过网格的 64）。
	# 行自己的高度里已经有富余（32 装 28 的字 ⇒ 上下各 2px），不靠容器的间隔留白。
	_box.add_theme_constant_override("separation", 0)
	# 子元素最小尺寸一变就重算面板尺寸：内容多大只能问内容盒
	# （滚动容器的最小尺寸恒为 0，隔着它问 _panel 问不出内容多大，见 _content_size）。
	_box.minimum_size_changed.connect(_fit_size)
	if config.has("matrix") or config.has("cell"):
		# **网格模式**（`matrix`：二维矩阵 / `cell`：等大格子）：**另起一个"网格区"**
		# （普通 Control，占竖排剩下的高）——写 `grid` 的子元素挂那儿，没写的（标题这类）留在竖排里
		# ⇒ 网格上方能有一行标题（见文件头）。竖排撑满视口高：网格按"网格区现在多大"排，
		# 面板变大变小都跟着重算（矩阵是缩放、等大网格是**换列数**），所以默认不会出滚动条
		# （等大网格排不下时例外：给网格区一个最小高，交给滚动，见 `_layout_uniform`）。
		_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_grid_box = Control.new()
		_grid_box.name = "Grid"
		_grid_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_grid_box.resized.connect(_layout_grid)    # 网格区一变就重摆（含第一次排完版那一帧）
		_box.add_child(_grid_box)
	_box.name = "Box"
	# **横向撑满视口**：ScrollContainer 只把子节点排到"它自己的最小尺寸"，不负责拉宽——不写这一句，
	# Box 就停在最小宽度，而折行文本的最小宽度是 0/1px ⇒ **里面的文字被压成一列**
	# （实测：320 宽的面板里正文只有 1px 宽、折成 74 行）。
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


## 覆写：**网格模式下要分流**——写了 `grid` 的子元素挪到网格区（`_grid_box`），其余（可折叠标题这类）
## 留在竖排里；再把网格区**挪到最后**，让它永远占"标题之下剩下的高"（顺序 = 谁在上不靠配置里的先后）。
## 其它情况与基类一样（free 子元素挂叠加层 / 贴角的进角落容器，见 UIBase._attach_child_control）。
## 被谁用：UIBase._build_children / add_child_element。
func _attach_child_control(child: UIBase, child_config: Dictionary) -> void:
	super(child, child_config)
	if _grid_box == null or bool(child_config.get("free", false)):
		return                                   # 非网格模式 / 自由定位的子元素：不参与网格
	if child_config.has("grid"):
		# **换父级要用 reparent**：基类刚把它挂在竖排（Box）上，而 Godot 4 的 add_child **不认**
		# "已经有父级"的节点（会报 already has a parent 并且什么都不做——实测：格子全留在竖排里堆成一列）。
		child.control.reparent(_grid_box, false)  # false = 不管全局坐标（位置随后由布局写）
	_box.move_child(_grid_box, -1)


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


## 内容需要多大：**内容盒 + 内边距 + 底图边距**（三项相加，不是取大）。
## **不能只问 `_panel`**：根 Control 是普通 Control 不汇总子元素（问它只得到"配置里写的那点值"，
## [宽, 0] 就成了高度 0 的退化矩形、画不出来也命中不到）；而 `_panel` 里隔着 ScrollContainer，
## 滚动容器的最小尺寸恒为 0 ⇒ 单问它只会得到"边距那么大"，内容等于没了。
## 另外 `PanelContainer` 的"最小尺寸"取的是 `max(底图边距, 子元素最小)`，不是相加——底图边距（带边距的图，
## 默认那张 8px）比内容大时它会**少报一整圈** ⇒ 面板矮/窄一圈、明明装得下却出滚动条（实测踩过）。
## 所以这里**自己把三项加起来**：内容盒 + `_margin()*2`（内边距）+ 底图样式的最小尺寸。
## `config["scroll"]` 的上限在这里收口：内容再多面板也只长到上限，多出来的进去滚动（见文件头）。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	var sb: StyleBox = _panel.get_theme_stylebox("panel")
	var sb_min: Vector2 = sb.get_minimum_size() if sb != null else Vector2.ZERO
	var need: Vector2 = _box.get_combined_minimum_size() + _margin() * 2.0 + sb_min
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


## 面板尺寸一定，就把子元素重摆一遍（按 config 选排法，见 `_layout_grid`）。
## 被谁用：UIBase._fit_size（build、拖"改尺寸"手柄、内容最小尺寸变化都会走到）。
func _fit_size() -> void:
	super._fit_size()
	_layout_grid()


## 按 config 选排法把子元素重摆一遍：
##   `matrix`  二维矩阵网格：跨格 / 跨行，格子按比例缩放（见 _layout_matrix）
##   `cell`    等大格子网格（背包那种）：格子等大，**列数随宽度变**（见 _layout_uniform）
## 两个都没配 ⇒ 什么都不做（普通竖排面板，行为与以前一样）。
## 被谁用：_fit_size、内容盒 resized（网格模式：视口一变就重摆）。
func _layout_grid() -> void:
	# **收起中不排网格**：格子都藏起来了，排了也看不见；而且"排不下就撑高网格区"（等大网格那一支）
	# 会把面板顶住不放 ⇒ 收起后仍是一大块空底（见 UIBase._fit_size 的"收起时高度让给内容"）。
	if bool(config.get("collapsed", false)):
		if _grid_box != null:
			_grid_box.custom_minimum_size = Vector2.ZERO
		return
	if config.has("matrix"):
		_layout_matrix()
	elif config.has("cell"):
		_layout_uniform()


## 把一个子元素摆到算好的格子上：**写回它自己的 config（size/position）再让它应用**——
## 这样它内部的排版（折行、子元素）与新尺寸一致，之后它自己的 `_fit_size` 也算出同样的值，
## 不会跟面板打架。被谁用：_layout_matrix、_layout_uniform。
func _place_cell(child: UIBase, r: Rect2) -> void:
	child.config["size"] = [r.size.x, r.size.y]
	child.config["position"] = [r.position.x, r.position.y]
	child._fit_size()
	child.refresh("position")


## 按 `config["matrix"]` 把**写了 `config["grid"]` 序号**的子元素摆进网格：
## 位置与尺寸 = `grid_rect(矩阵, 网格区当前大小, gap, 0, 序号)`——网格区变一点，格子就按比例重算一次
## ⇒ 拖"改尺寸"手柄时**排版不变、大小位置跟着缩放**。四周留白就是面板的 `margin`（网格区已在它里面），
## 格间距写 `config["gap"]`（不写 = 4）。没写 `grid` 的子元素不参与网格（标题、贴角的关闭按钮照旧）。
## 网格区的尺寸是"竖排里剩下的高"（见 `_grid_box`），所以面板的 `size` 要**定死**：没有"内容需要多大"可言。
## 写回的是子元素自己的 `config`（size/position）再让它应用：它内部的排版（折行、子元素）就与新尺寸
## 一致，之后它自己的 `_fit_size` 也算出同样的值，不会跟面板打架。
## 被谁用：_layout_grid（由 _fit_size 与网格区 resized 进来）。
func _layout_matrix() -> void:
	var m: Variant = config.get("matrix")
	if not (m is Array) or _grid_box == null or _grid_box.size.x <= 0.0 or _grid_box.size.y <= 0.0:
		return                       # 布局还没跑（网格区还是 0）：等 _grid_box.resized 再算
	var gap: float = float(config.get("gap", 4))
	for child in children:
		if not child.config.has("grid"):
			continue                 # 没写序号 = 不进网格（保持原样）
		_place_cell(child, grid_rect(m, [_grid_box.size.x, _grid_box.size.y], gap, 0.0, child.config["grid"]))


## **等大网格**（背包那种）：每个子元素一样大（`config["cell"]` = [宽, 高]，方形 / 长方形都行），
## 列数由**网格区宽度**决定（能塞几列就几列）⇒ 拖宽一点，东西就"往上走"一行；行数 = 个数 / 列数 向上取整。
## 剩下不足一格的空位**摊进间距**（列 / 行间距变大，上界是一格的大小）——所以拖到"不够一列"时看到的是
## 间距变宽，直到能多塞下一列为止（那时列数 +1、间距回到最小）。这正是"多余不足一格 ⇒ gap 变多"。
## 排不下的情况（行数 × 格子 + 间距 > 网格区高）：给网格区一个最小高 ⇒ 面板的滚动条出现，滚着看。
## 参与网格的子元素 = **非 free 的**（free 的挂叠加层，如关闭按钮）；顺序 = config 里 children 的顺序。
## 被谁用：_layout_grid。
func _layout_uniform() -> void:
	@warning_ignore_start("unsafe_cast")
	var c: Variant = config.get("cell")
	if not (c is Array) or (c as Array).size() < 2 or _grid_box == null:
		return
	var cell: Vector2 = Vector2(float((c as Array)[0]), float((c as Array)[1]))
	if cell.x <= 0.0 or cell.y <= 0.0 or _grid_box.size.x <= 0.0:
		return                       # 布局还没跑（网格区还是 0）：等 _grid_box.resized 再算
	var gap: float = float(config.get("gap", 4))
	var items: Array = []
	for child in children:
		if not bool(child.config.get("free", false)):
			items.append(child)
	if items.is_empty():
		return
	var area: Vector2 = _grid_box.size
	var cols: int = clampi(int((area.x + gap) / (cell.x + gap)), 1, items.size())
	var rows: int = ceili(float(items.size()) / float(cols))
	# 空位摊进间距：`clampf(摊出来的间距, 最小间距, 一格的大小)`——不够摊就退回最小间距，
	# 超出"一格"就不再摊了（留白），于是"不够一格"的余量表现为间距变宽。
	var gx: float = gap
	if cols > 1:
		gx = clampf((area.x - float(cols) * cell.x) / float(cols - 1), gap, cell.x + gap)
	var gy: float = gap
	if rows > 1:
		gy = clampf((area.y - float(rows) * cell.y) / float(rows - 1), gap, cell.y + gap)
	# 排不下 ⇒ 撑高**网格区**（滚动条交给面板的滚动容器）；排得下 ⇒ 保持 0（= 撑满视口，不出滚动条）。
	# **判断要用"视口高"（滚动容器的尺寸），不能用网格区自己的高**：网格区被撑高之后它自己就是那个高
	# （`area.y` == need_h）⇒ 拿它比会把刚设的最小高又清成 0（实测：滚动条闪一下就没、怎么都滚不动）。
	var sc: ScrollContainer = _panel.get_node_or_null("Margin/Scroller") as ScrollContainer
	var view_h: float = sc.size.y if sc != null and sc.size.y > 0.0 else area.y
	var need_h: float = float(rows) * cell.y + float(rows - 1) * gap
	_grid_box.custom_minimum_size = Vector2(0.0, need_h if need_h > view_h + 0.5 else 0.0)
	for i in items.size():
		var col: int = i % cols
		@warning_ignore("integer_division")
		var row: int = i / cols     # 整除就是"第几行"（余数是列），不是漏了小数
		_place_cell(items[i], Rect2(
			float(col) * (cell.x + gx), float(row) * (cell.y + gy), cell.x, cell.y))
	@warning_ignore_restore("unsafe_cast")


## 二维矩阵 → 某个编号的**位置与尺寸**（纯几何，不装配 UI；静态，配置层也能调）。
## 输入：
##   matrix      二维矩阵，一行一个子数组；**同一个编号出现几格 = 那个元素跨几格 / 跨几行**（编号任意值）；
##   panel_size  [宽, 高]：网格区总尺寸（含四周 padding；矩阵面板传的就是内容区大小）；
##   gap         格与格的间距；pad  四周内边距；id  要查的元素编号。
## 返回 Rect2（position 相对网格区左上角）。编号不存在 / 矩阵为空 ⇒ 空 Rect2 并警告一次；
## L 形（非矩形区域）表达不了 ⇒ 警告一次、按外接矩形放。
## 被谁用：_layout_matrix（演示窗 MatrixTest 只写 `grid` 配置，不直接调它）。
@warning_ignore_start("unsafe_cast")
static func grid_rect(matrix: Array, panel_size: Array, gap: float, pad: float, id: Variant) -> Rect2:
	if matrix.is_empty() or (matrix[0] as Array).is_empty():
		push_warning("grid_rect: 矩阵是空的")
		return Rect2()
	var rows: int = matrix.size()
	var cols: int = (matrix[0] as Array).size()
	var cell: Vector2 = Vector2(
		(float(panel_size[0]) - pad * 2.0 - gap * float(cols - 1)) / float(cols),
		(float(panel_size[1]) - pad * 2.0 - gap * float(rows - 1)) / float(rows))
	var x0: int = 1 << 30
	var y0: int = 1 << 30
	var x1: int = -1
	var y1: int = -1
	var count: int = 0
	for r in rows:
		for c in cols:
			if (matrix[r] as Array)[c] != id:
				continue
			count += 1
			x0 = mini(x0, c)
			y0 = mini(y0, r)
			x1 = maxi(x1, c)
			y1 = maxi(y1, r)
	if count == 0:
		push_warning("grid_rect: 矩阵里没有编号 %s" % str(id))
		return Rect2()
	if count != (x1 - x0 + 1) * (y1 - y0 + 1):
		push_warning("grid_rect: 编号 %s 的格子不是矩形（%d 格 ≠ %dx%d），按外接矩形放"
			% [str(id), count, x1 - x0 + 1, y1 - y0 + 1])
	return Rect2(
		pad + x0 * (cell.x + gap), pad + y0 * (cell.y + gap),
		float(x1 - x0 + 1) * cell.x + float(x1 - x0) * gap,
		float(y1 - y0 + 1) * cell.y + float(y1 - y0) * gap)
@warning_ignore_restore("unsafe_cast")


## 把 config["background"] 的图做成九宫格面板底。
## 覆写基类：底要套在**内层 PanelContainer**（_panel）的 "panel" 上——本元素的根控件是普通 Control，
## 它自己不画 StyleBox，套在它身上什么也看不见。
## 有了它整块面板就能用一张图当底（键盘 UI 那种），子元素照常画在上面——
## 不用专门放个 Image 元素当背景：Image 属于"内容"，摆在叠加层上会盖住其它子元素。
## 被谁用：UIBase._apply_config。
func _apply_background(path: String) -> void:
	# **没写 `background` 就用全局默认底图**（`SysCfg.ui_background` + `ui_background_slice`）：
	# 面板就是全项目的"窗口"，不给底就是引擎默认那块半透明黑（难看）。
	# 想"这个面板不要底"就**显式写** `"background": ""`（写了空串 = 明确不要，与"没写"区分开）。
	# **所有面板都套默认底**（顶层窗口、嵌套的网格格/子面板都算"UI"），**圆角边距（slice）照留**
	# （用户要求：圆角半框要留）。代价是嵌套的格子要按"格宽 - 圆角边距 - margin"收窄自己的内容
	# （如角色看板把 CELL_CHARS 调小），否则内容最小宽会超过格宽、文字被裁。
	if path == "" and not config.has("background"):
		path = SysCfg.ui_background
	var style: StyleBoxTexture = _make_background(path)
	if style == null:
		return
	_panel.add_theme_stylebox_override("panel", style)
