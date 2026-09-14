class_name UiSys
extends BaseClass
## UI 系统（设计见 Script/UI/UI.md）。
## 命名与其它系统对齐：类名用短名 `XxxSys`（`CharSys` / `TimeSys` / `MapSys` / `CmdSys` / `InputSys` 同理），
## 文件名保持 `XxxSystem.gd`——与 `CharacterSystem.gd`(CharSys)、`InputSystem.gd`(InputSys) 一套约定。
##
## 职责：UI 的**开启与登记**——全项目唯一的开启入口 `open_ui()` 在本类，
## 独立 UI（挂 UI 根）与"挂在别的 UI 下"的 UI（菜单链）走同一条路，**没有任何按类型特判**。
## 交互（关闭/拖动/渐隐/改内容）在 UIInteract 静态类，元素按事件发指令驱动。
##
## **挂载规则**（决定 UI 树，从而决定"关谁连谁一起关"与指令里的 `$parent` 链）：
##   有 anchor（触发它的那个元素，如菜单项）→ **挂在 anchor 下面**；
##   没有 anchor → 挂在 host 下面；host 也没有 → 挂在 UI 根（独立 UI）。
##   于是"菜单开子菜单"得到的是一棵**单链子树**：`MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`
##   ⇒ 关父级时整条链一起隐藏（可见性继承）；
##   ⇒ 失焦判定沿 parent 链就能认出"指针在我这条链上"（见 close_blur_ui）。
##
## **登记名规则**（本类唯一的"寻址"约定）：
##   - 没有挂载点（独立 UI）→ 登记名就是预设名，如 `MiniHUD`；
##   - 有挂载点 → 登记名 = `挂载点的登记名 + "=>" + 预设名`，如 `MiniHUD=>Menu`、
##     `MiniHUD=>Menu/Edit=>MenuEdit`（子菜单挂在菜单项下，所以名字也层层接下去）。
##   于是"同一个地方再开同一个 UI"就是**一次字典查找**（`uis.get(登记名)`），
##   不需要"按同一宿主 + 同一预设遍历所有实例"这种特判。
##   UI 内部的子元素继续在后面追加 `/子元素名`（如 `MiniHUD=>Menu/Close`），只用于查找与调试。
##
## **成员全部是静态的**：日常调用直接写 `UiSys.open_ui(...)` / `UiSys.uis` / `UiSys.root`，
## 不要绕 `Sys.uiSys`（那个实例只用来在启动时跑一次 `_init` 建 UI 根，见下）。

## UI 根（CanvasLayer）：所有"没有宿主"的 UI 都挂这里。
## 被谁用：_init（创建）、_build_open（挂独立 UI）。
static var root: CanvasLayer
## 已登记的 UI：登记名 -> 实例（规则见文件头）。
## 被谁用：open_ui（复用查找）、get_ui（按名取）、find_name（反查）、PointerDetect._ui_at（命中）、
##         has_blur_ui / close_blur_ui（失焦关闭）。
static var uis: Dictionary[String, UIBase] = {}


## 启动触发（**唯一的实例方法**）：建 UI 根并延迟挂到树上。
## 被谁用：Sys.init_sub_system（`uiSys = UiSys.new()`）——别的地方不要 new 它，直接用静态成员。
func _init() -> void:
	root = CanvasLayer.new()
	root.name = "UIRoot"
	# 初始化发生在 Sys._ready()（引擎仍在建子节点），需延迟到本帧空闲再挂载
	Sys.sys.get_tree().root.add_child.call_deferred(root)


## 开启一个 UI —— **全项目唯一的开启入口**（不要再写第二个，菜单与普通 UI 都走这里）。
## 被谁用：UIInteract.open_ui（配置指令的唯一入口）、Test.ui_test（测试）。
##   preset_name = 预设名（见 Config/UI/）
##   host        = 宿主（挂载点）。没有 anchor 时挂到它下面；不给（null）+ 没有 anchor = 独立 UI（挂 UI 根）。
##   anchor      = 位置锚点，同时也是**挂载点**：多级菜单传"触发它的那个菜单项"，
##                 子菜单因此成为该菜单项的后代（整条菜单链是一棵子树，见文件头的挂载规则）。
## 复用规则：按登记名查（登记名由实际挂载点算出）——**已存在就只显示 + 重新摆位，不重建控件**。
## 返回：开出来的 UI（找不到预设/建不出来为 null）。
static func open_ui(preset_name: String, host: UIBase = null, anchor: UIBase = null) -> UIBase:
	var preset: UIPreset = UIPreset.get_(preset_name)
	if preset == null or preset.ui_name == "":
		push_warning("UiSys.open_ui: 找不到预设「%s」（见 Config/UI/）" % preset_name)
		return null
	# 挂载点：锚点优先（子菜单挂到菜单项下 ⇒ 菜单链是一棵子树），其次宿主，都没有就挂 UI 根
	var mount: UIBase = anchor if anchor != null else host
	var ui: UIBase = uis.get(_reg_name(mount, preset_name))
	if ui == null:
		ui = _build_open(preset, preset_name, mount)
	if ui == null:
		return null
	_place(ui, anchor)
	return ui


## 取一个已登记的 UI（用登记名，如 "MiniHUD"、"MiniHUD=>Menu"、"MiniHUD=>Menu/Close"）。
## 被谁用：Test.ui_test（拿滚动区改内容）、外部按名取子元素。
static func get_ui(name: String) -> UIBase:
	return uis.get(name)


## 给已登记的 UI 追加一个子元素并登记（由 UIBase.add_child_element 调用）。
## 登记后才可能被指针命中；父元素没登记就警告（子元素会永远收不到事件）。
##   reg_name = 指定登记名（**开 UI 时用**：UiSys._build_open 传 `挂载点=>预设名`，
##              这样"同一个地方再开同一个 UI"才查得到、能复用）；
##              留空 = 配置/运行时的普通子元素，按 `父登记名/子名` 登记。
## 被谁用：UIBase.add_child_element（子元素、以及 _build_open 开的 UI）。
static func register_child(parent: UIBase, child: UIBase, reg_name: String = "") -> void:
	if reg_name != "":
		_register_tree(child, reg_name)
		return
	var parent_name: String = find_name(parent)
	if parent_name == "":
		push_warning("UiSys: 追加子元素「%s」时父元素未登记，该元素无法被指针命中" % child.name)
		return
	_register_tree(child, parent_name + "/" + child.name)


## 反查一个已登记 UI 的登记名（未登记返回空串）。
## 被谁用：_reg_name（拼"挂载点=>预设"）、register_child（拼子元素的登记名）。
static func find_name(ui: UIBase) -> String:
	for key in uis:
		if uis[key] == ui:
			return key
	return ""


## 拼登记名：无挂载点 → 预设名本身；有挂载点 → `挂载点的登记名=>预设名`。
## 这一步就是"是否能复用"的全部判据，所以不需要任何按 UI 类型的特判。
## 被谁用：open_ui。
static func _reg_name(mount: UIBase, preset_name: String) -> String:
	if mount == null:
		return preset_name
	var mount_name: String = find_name(mount)
	if mount_name == "":
		push_warning("UiSys.open_ui: 挂载点「%s」未登记，拼不出唯一登记名，退化为预设名" % mount.name)
		return preset_name
	return mount_name + "=>" + preset_name


## 现场造一个开启目标并登记：mount 为空 → 建预设自己那份挂 UI 根；有 mount → 挂到它下面。
## 挂到别处的一律用**深拷贝模板**（各实例互不影响："加按钮/加绑定"只改自己这一份）。
## 被谁用：open_ui。
static func _build_open(preset: UIPreset, preset_name: String, mount: UIBase) -> UIBase:
	if mount == null:
		var ui: UIBase = preset.ui
		root.add_child(ui.build())
		_register_tree(ui, preset_name)
		Msg.send_ui_create(ui)
		return ui
	return mount.add_child_element(preset_name, preset.ui_name, preset.config.duplicate(true),
		_reg_name(mount, preset_name))


## 按被开启 UI 自己的 config["open_at"] 摆位置并显示（Enums.OpenAt）：
##   CONFIG（默认，不写就是它）→ 摆回配置声明的 position（独立面板；被拖动过就回到初值）
##   POINTER                   → 开在指针处（右键菜单仍要传 anchor：它决定了挂在谁下面）
##   ANCHOR_TOP_RIGHT          → 开在 anchor 的右上角顶点（多级菜单传触发它的那个菜单项）
## 被谁用：open_ui。
static func _place(ui: UIBase, anchor: UIBase) -> void:
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
			push_warning("UiSys.open_ui: 「%s」要求开在锚点右上角，但锚点不可用，改在指针处开" % ui.name)
			ui.show_at(InputSys.mouse_position)
	else:
		ui.reset_position()
		ui.control.show()


## 登记整棵 UI 树：根用登记名，子元素用 "登记名/子名"。
## 子元素也进 uis，PointerDetect 才能把指针命中派发到具体子元素（如关闭按钮、菜单项）。
## 被谁用：_build_open（独立 UI）、register_child（子元素 / 指定登记名开的 UI）。
static func _register_tree(ui: UIBase, full_name: String) -> void:
	uis[full_name] = ui
	for child in ui.children:
		_register_tree(child, full_name + "/" + child.name)


## ---------- 失焦关闭（纯配置驱动，与"是不是菜单"无关）----------

## 有没有"配了 `close_on_blur` 且正显示"的 UI。
## 被谁用：PointerDetect.key（先判一下，省掉没必要的命中刷新与遍历）。
static func has_blur_ui() -> bool:
	for ui: UIBase in uis.values():
		if ui.control != null and bool(ui.config.get("close_on_blur", false)) and ui.control.is_visible_in_tree():
			return true
	return false


## 关掉"指针已经不在上面"的 UI：遍历所有配了 `close_on_blur` 且正显示的 UI，
## 指针不在它（或它的子孙元素/子孙 UI）上 → 走通用的 UIInteract.close（hide + 广播）。
## 判定只要 parent 链，不需要"父子菜单链"这种登记：菜单链本身就是一棵子树
## （子菜单挂在触发它的菜单项下，见文件头的挂载规则），所以鼠标在子菜单上时，
## 父菜单沿链就能找到自己 ⇒ 不关；父 UI 一 hide，链上的子 UI 也随可见性继承一起不可见。
## 被谁用：PointerDetect.key（派发完按键事件、刷新命中之后）。
static func close_blur_ui(hover_ui: UIBase) -> void:
	for ui: UIBase in uis.values():
		if ui.control == null or not bool(ui.config.get("close_on_blur", false)):
			continue
		if not ui.control.is_visible_in_tree():
			continue
		if not _is_inside(ui, hover_ui):
			UIInteract.close(ui)


## 指针是否在这个 UI 上：hover 沿 parent 链向上能找到 ui 即为"内"（所以它的子元素也算）。
## 被谁用：close_blur_ui。
static func _is_inside(ui: UIBase, hover_ui: UIBase) -> bool:
	var cur: UIBase = hover_ui
	while cur != null:
		if cur == ui:
			return true
		cur = cur.parent
	return false
