class_name UIInteract_OpenClose
extends UIInteractBase
## UI 交互：**开 / 关**（`UIInteract.open` / `UIInteract.close`）。
## 这一对放在同一个文件里：它们是同一个东西的两面——开是"复用 + 摆位 + 显示"，关是"隐藏"，
## 而 `close` 的第二个参数（关掉挂在 target 下的某个预设 UI）正好与 `open` 的开子 UI 对称。
##
## **开启和它的子方法都在本文件**（`open` / `_build_open` / `_place` / `_child_ui`）：
## 它们只有开启与关闭用得到，所以按"子函数跟着调用者走"从 UiSys 搬了过来——
## UiSys 现在只剩"登记表 + 登记名规则 + 登记 + 取件"，既不管开启、也不管失焦关闭。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd。
##
## 失焦关闭（close_blur_ui）也在这个文件：**只有"开出来的 UI"才可能配 `close_on_blur`**，
## 所以 open 顺手把它记进候选列表 `_blur_uis`，失焦判定只遍历这个小列表（不必每次扫整张登记表）。

## 失焦关闭的候选：**当前开着、且配置里写了 `close_on_blur` 的 UI**。
## **open 登记、close 摘掉**（所以关过再开能自动回来，列表也始终只装着"当前真的在开着的那几个"）。
## 注：按 open 那一刻的配置登记——运行时改 close_on_blur 的玩法目前没有（真要有就再登记一次）。
static var _blur_uis: Array[UIBase] = []


## 开启一个 UI —— **全项目唯一的开启入口**（不要再写第二个；普通 UI 与菜单同一条路，没有任何按类型特判）。
## 指令入口就是本函数：`UIInteract.open`。
##   target      = 宿主（挂载点）。没有 anchor 时挂到它下面；
##                 **target 与 anchor 都不给就是独立 UI**（挂 UI 根）——指令里用 `--preset_name xxx` 跳过它。
##   preset_name = 预设名（见 Config/UI/）
##   anchor      = 位置锚点，同时也是**挂载点**（锚点优先于宿主）：多级菜单传"触发它的那个菜单项"，
##                 子菜单挂在该菜单项下 ⇒ 整条菜单链是一棵子树（关父级全关、失焦判定沿 parent 链）
## 复用规则：按（挂载点 + 预设名）查登记名——**已存在就只显示 + 重新摆位，不重建控件**。
## 指令写法：UIInteract.open $self Menu $self        （面板右键 → 指针处开菜单）
##           UIInteract.open --preset_name MiniHUD  （独立 UI → 开在配置声明的位置）
## 被谁用：Config/UI 里各预设的 "events"、Test.ui_test（测试也走指令，不抄近路）、外部想直接拿实例时。
## 返回：开出来的 UI（找不到预设/建不出来为 null）。
static func open(target: UIBase = null, preset_name: String = "", anchor: UIBase = null) -> UIBase:
	var preset: UIPreset = UIPreset.get_(preset_name)
	if preset == null or preset.ui_name == "":
		push_warning("UIInteract.open: 找不到预设「%s」（见 Config/UI/）" % preset_name)
		return null
	# 挂载点：锚点优先（子菜单挂到菜单项下 ⇒ 菜单链是一棵子树），其次宿主，都没有就挂 UI 根
	var mount: UIBase = anchor if anchor != null else target
	var ui: UIBase = _child_ui(mount, preset_name)
	if ui == null:
		ui = _build_open(preset, preset_name, mount)
	if ui == null:
		return null
	# 只有开出来的 UI 才可能是"失焦要关"的：配了就记进候选（重复开同一个不会重复记）
	if bool(ui.config.get("close_on_blur", false)) and not _blur_uis.has(ui):
		_blur_uis.append(ui)
	_place(ui, anchor)
	# 新开的排到最前（也会顺带把它的窗口提到最前，见 UIInteract_SetTop）
	UIInteract_SetTop.set_top(ui)
	return ui


## 关闭（隐藏）UI —— **一个函数管两种情况**：
##   只有 target          → 关 target 自己；
##   还给了 preset_name   → 关"挂在 target 下的那个预设 UI"（按挂载点 + 预设名查回来再关）。
## 为什么要第二种：菜单项深处手上只有一个"面板"的引用（`$parent.parent.parent.parent`）和一个预设名，
## 而它要关的是挂在那个面板下的子 UI（如 CloseButton），不是面板自己。
## 只是 hide，实例留在原地；**重开统一走 UIInteract.open**（显示 + 按 open_at 重新摆位，不重建控件）。
## 查不到（没开过）就什么都不做（幂等）。
## 被谁用：关闭按钮 / 菜单的"关闭"项 / 开关式按钮的"移除"一侧；本文件的 close_blur_ui 也走它。
static func close(target: UIBase, preset_name: String = "") -> void:
	var ui := _as_ui(target, "close")
	if ui == null:
		return
	if preset_name != "":
		ui = _child_ui(ui, preset_name)
		if ui == null:
			# 分开两种情况：预设名压根不存在 ⇒ 指令写错了（要提醒，不然静默）；
			# 预设存在、只是没开过 ⇒ 幂等（什么都不做是对的，不吵）
			if UIPreset.get_(preset_name) == null:
				push_warning("UIInteract.close: 没有「%s」这个预设（名字写错了吗？见 Config/UI/）" % preset_name)
			return
	if ui.control != null:
		ui.control.hide()
	Msg.send_ui_close(ui)


## 按"挂载点 + 预设名"取已登记的 UI —— 开（复用查找）与关（找要关的子 UI）共用的那把钥匙。
## 登记名规则在 UiSys._reg_name（全项目唯一的一条寻址约定，登记与取件共用），本函数只是它的取件形式。
## 原来叫 UiSys.get_child_ui：只有开/关用得到，就跟着搬到本文件了。
## 被谁用：open、close。
static func _child_ui(mount: UIBase, preset_name: String) -> UIBase:
	return UiSys.uis.get(UiSys._reg_name(mount, preset_name))


## 现场造一个开启目标并登记：mount 为空 → 建预设自己那份挂 UI 根；有 mount → 挂到它下面。
## 挂到别处的一律用**深拷贝模板**（各实例互不影响："加按钮/加绑定"只改自己这一份）。
## 被谁用：open。
static func _build_open(preset: UIPreset, preset_name: String, mount: UIBase) -> UIBase:
	if mount == null:
		var ui: UIBase = preset.ui
		UiSys.root.add_child(ui.build())
		UiSys._register_tree(ui, preset_name)
		Msg.send_ui_create(ui)
		return ui
	return mount.add_child_element(preset_name, preset.ui_name, preset.config.duplicate(true))


## 按被开启 UI 自己的 config["open_at"] 摆位置并显示（Enums.OpenAt）：
##   CONFIG（默认，不写就是它）→ 摆回配置声明的 position（独立面板；被拖动过就回到初值）
##   POINTER                   → 开在指针处（右键菜单仍要传 anchor：它决定了挂在谁下面）
##   ANCHOR_TOP_RIGHT          → 开在 anchor 的右上角顶点（多级菜单传触发它的那个菜单项）
##   ANCHOR_TOP_RIGHT_IN       → 开在 anchor **内部**的右上角（按自己宽度内缩；如面板的 "X" 按钮）
##   ANCHOR_BOTTOM_RIGHT_IN    → 开在 anchor **内部**的右下角（如缩放手柄）
## 被谁用：open。
static func _place(ui: UIBase, anchor: UIBase) -> void:
	if ui.control == null:
		return
	var strategy: int = int(ui.config.get("open_at", Enums.OpenAt.CONFIG))
	if strategy == Enums.OpenAt.POINTER:
		ui.show_at(InputSys.mouse_position)
	elif strategy in [Enums.OpenAt.ANCHOR_TOP_RIGHT, Enums.OpenAt.ANCHOR_TOP_RIGHT_IN,
			Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN]:
		if anchor == null or anchor.control == null:
			push_warning("UIInteract.open: 「%s」要求开在锚点角上，但锚点不可用，改在指针处开" % ui.name)
			ui.show_at(InputSys.mouse_position)
			return
		var rect: Rect2 = anchor.control.get_global_rect()
		# IN 版：按自己的宽/高往内缩，落在锚点内部（见 Enums.OpenAt 的说明）
		var inside: bool = strategy != Enums.OpenAt.ANCHOR_TOP_RIGHT
		var bottom: bool = strategy == Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN
		var x: float = rect.end.x - ui.control.size.x if inside else rect.end.x
		var y: float = rect.end.y - ui.control.size.y if bottom else rect.position.y
		ui.show_at(Vector2(x, y))
	else:
		ui.reset_position()
		ui.control.show()


## ---------- 失焦关闭（纯配置驱动，与"是不是菜单"无关）----------
## 为什么放在这里：失焦要关的只可能是**开出来的**、写了 `close_on_blur` 的 UI（配置子元素不会被单独关），
## 所以候选就记在 open 那里（`_blur_uis`），这里只做判定与关。

## 关掉"指针已经不在上面"的 UI：遍历候选列表（= 配了 `close_on_blur` 且正开着的 UI），
## 指针不在它（或它的子孙元素/子孙 UI）上 → 走本文件的 close（hide + 广播 + 从候选里摘掉）。
## 判定只要 parent 链，不需要"父子菜单链"这种登记：菜单链本身就是一棵子树
## （子菜单挂在触发它的菜单项下，见 UiSys 文件头的挂载规则），所以鼠标在子菜单上时，
## 父菜单沿链就能找到自己 ⇒ 不关；父 UI 一 hide，链上的子 UI 也随可见性继承一起不可见。
## 实现上**边遍历边 close 会改到 `_blur_uis`**（close 里要摘掉候选），所以先收集再关。
## 被谁用：PointerDetect._process（每帧刷新命中之后，且仅当上一帧派发过事件）。
static func close_blur_ui(hover_ui: UIBase) -> void:
	var closing: Array[UIBase] = []
	for ui: UIBase in _blur_uis:
		# 尺寸还没算出来的先当它"还在指针下"：布局没跑时 get_global_rect() 是退化矩形，
		# 会被误判成"指针在外面"当场关掉。（判定已挪到下一次刷新，这里算第二道保险。）
		var rect: Rect2 = ui.control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if not _is_inside(ui, hover_ui):
			closing.append(ui)
	for ui: UIBase in closing:
		close(ui)
		_blur_uis.erase(ui)


## 指针是否在这个 UI 上：hover 沿 parent 链向上能找到 ui 即为"内"（所以它的子元素也算）。
## 被谁用：close_blur_ui。
static func _is_inside(ui: UIBase, hover_ui: UIBase) -> bool:
	var cur: UIBase = hover_ui
	while cur != null:
		if cur == ui:
			return true
		cur = cur.parent
	return false
