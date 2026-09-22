class_name UIInteract_OpenClose
extends UIInteractBase
## UI 交互：**开 / 关**（`UIInteract.open` / `UIInteract.close`）。
## 这一对放在同一个文件里：它们是同一个东西的两面——开是"复用 + 摆位 + 显示"，关是"隐藏"，
## 而 `close` 的第二个参数（关掉挂在 target 下的某个预设 UI）正好与 `open` 的开子 UI 对称。
##
## **开启和它的子方法都在本文件**（`open` / `_build_open` / `_place` / `_child_ui`）：
## 它们只有开启与关闭用得到，所以按"子函数跟着调用者走"从 UISys 搬了过来——
## UISys 现在只剩"登记表 + 登记名规则 + 登记 + 取件"，既不管开启、也不管失焦关闭。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd。
##
## 失焦关闭（点关 / 移开关）也在这个文件：**只有"开出来的 UI"才可能有这两种行为**，
## 所以 open 顺手把它们记进候选表，判定只遍历这两张小表（不必每次扫整张登记表）。
##
## 两种关闭行为：
##   close_on_blur：**点关** —— 有按键派发时判一次（右键菜单：点别处才关，鼠标划过不会把它关掉）
##   close_on_move：**移开关** —— 指针一动就判（"鼠标移上去自动展开"的子菜单：挪开就收起来）
## 两者都能由 open 的参数临时给（推荐，见 open 的说明），也能写在被开 UI 自己的 config 里。


## 开启一个 UI —— **全项目唯一的开启入口**（不要再写第二个；普通 UI 与菜单同一条路，没有任何按类型特判）。
## 指令入口就是本函数：`UIInteract.open`。
##   target      = 宿主（挂载点）。没有 anchor 时挂到它下面；
##                 **target 与 anchor 都不给就是独立 UI**（挂 UI 根）——指令里写 `preset_name="xxx"` 跳过它。
##   preset_name = 预设名（见 Config/UI/）
##   anchor      = 位置锚点，同时也是**挂载点**（锚点优先于宿主）：多级菜单传"触发它的那个菜单项"，
##                 子菜单挂在该菜单项下 ⇒ 整条菜单链是一棵子树（关父级全关、失焦判定沿 parent 链）
##   host        = **这次打开的 UI 要管理的对象**，给一个 UI（如 `host=@self`、`host=@self.parent`；
##                 不给 = 沿链回退，默认管最外层那个窗口）。**它不是挂载点**：挂在哪、摆在哪仍由
##                 target / anchor 决定。解析规则见 UIBase._find_host（"最近声明优先，没声明回退顶层"）。
##                 落地时把它的**注册名**记进 config["host"]（可读、能存盘；没登记名字才退回实例 ID）。
## 复用规则：按（挂载点 + 预设名）查登记名——**已存在就只显示 + 重新摆位，不重建控件**。
##
## 关闭行为两个开关（bool，默认 false = 不启用）：
##   close_on_blur = true  点关：有按键派发时，指针不在它上面就关 —— 右键菜单那种
##   close_on_move = true  移开关：指针一动，不在它（或其挂载点）上就关 —— hover 展开的子菜单那种
## **要在开的这一句直接给**（不是写进预设）：它们取决于"在哪开、为什么开"，与"这个预设长什么样"无关；
## 写进预设的话，每加一层子菜单就得记得抄一遍，漏一处那个 UI 就永远关不掉。
## 类型就是 bool，字符串/数字怎么变 bool 由指令系统按签名处理（CmdSys._coerce），这里不再自己认。
##
## 指令写法：
##   UIInteract.open(@self, "Menu", @self, close_on_blur=true)       面板右键 → 指针处开菜单（点别处关）
##   UIInteract.open(preset_name="MiniHUD")                        独立 UI → 开在配置声明的位置
##   UIInteract.open(@self, "MenuEdit", @self, close_on_move=true)   hover 展开的子菜单：挪开就收
##   UIInteract.open(@self, "Menu", @self, host=@self)                这个菜单改管自己（不是最外层窗口）
##   UIInteract.open(@self, "Menu", @self, host=@self.parent)         或者管别的 UI（取值链能算出来就行）
## 被谁用：Config/UI 里各预设的 "events"、Test.ui_test（测试也走指令，不抄近路）、外部想直接拿实例时。
## 返回：开出来的 UI（找不到预设/建不出来为 null）。
## 独立 UI（没有挂载点）的登记名前缀：`UI/预设名`（见 UISys 的登记名规则）。
const UI_ROOT: String = "UI/"


static func open(target: UIBase = null, preset_name: String = "", anchor: UIBase = null,
		close_on_blur: bool = false, close_on_move: bool = false, host: UIBase = null,
		content_cmd: String = "", config: Variant = null) -> UIBase:
	var preset: UIPreset = UIPreset.get_(preset_name)
	if preset == null or preset.ui_name == "":
		push_warning("UIInteract.open: 找不到预设「%s」（见 Config/UI/）" % preset_name)
		return null
	# 挂载点：锚点优先（子菜单挂到菜单项下 ⇒ 菜单链是一棵子树），其次宿主，都没有就挂 UI 根
	var mount: UIBase = anchor if anchor != null else target
	# 管理对象先算出来——**必须在 build 之前就写进配置**：像 UI_Editor 这种"登记时就按 host 找目标、
	# 然后把路径写进各行"的元素，晚一步写它就按**挂载点链上的老 host**铺内容了（实测踩过：
	# 在编辑器里再开编辑器，第二层铺出来却指着最外层那个 UI）。**写注册名**（见 RegSys）。
	var host_name: String = RegSys.name_of(host) if host != null else ""
	# 这次打开要带上的一次性配置（**都要在 build 之前写**，理由同上）：
	#   host        —— 管理对象；
	#   content_cmd —— 要"监视 / 编辑"的对象（任何 UI 都能带：显示项见 UIBase.refresh，编辑器见 UI_Editor）；
	#   config      —— **一份 config 片段**：写什么就覆盖预设里同名的那项。
	#                  两种写法等价、可混用（见 CmdSys 的「任意配置键」约定）：
	#                    · 直接写键名（推荐）：`content_cmd="host.config", size=[200, 0]`；
	#                    · 或给一整份字典：`config={...}` / `config=某个静态变量`。
	#                  直接写的键覆盖字典里同名的；`content_cmd` 是"要看 / 编辑哪个对象"的简写。
	var extra: Dictionary = {}
	if config is Dictionary:
		extra = (config as Dictionary).duplicate(true)
	if host_name != "":
		extra["host"] = host_name
	if content_cmd != "":
		extra["content_cmd"] = content_cmd
	var ui: UIBase = _child_ui(mount, preset_name)
	if ui == null:
		ui = _build_open(preset, preset_name, mount, extra)
	if ui == null:
		return null
	ui.config.merge(extra, true)             # 复用路径也写一次（"重开一次换个对象 / 换个管理对象"要改得动）
	# 关闭行为：**总是按参数写**（默认 false = 不启用）。要哪种就在开的这一句写出来，
	# 预设里不再声明它——"在哪开、为什么开"只有开的那一句知道。
	ui.config["close_on_blur"] = close_on_blur
	ui.config["close_on_move"] = close_on_move
	_place(ui, anchor)
	# 新开的排到最前（也会顺带把它的窗口提到最前，见 UIInteract_SetTop）
	UIInteract_SetTop.set_top(ui)
	_reg_blur(ui)
	return ui


## 关闭（隐藏）UI —— **一个函数管两种情况**：
##   只有 target          → 关 target 自己；
##   还给了 preset_name   → 关"挂在 target 下的那个预设 UI"（按挂载点 + 预设名查回来再关）。
## 为什么要第二种：菜单项手上只有"管理对象"（`host`）和一个预设名，
## 而它要关的是挂在那个 UI 下的子 UI（如 CloseButton），不是那个 UI 自己。
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
	# 从两张失焦候选表里都摘掉（关过再开时 open 会重新登记 ⇒"显示着"与"在表里"始终一致）
	_blur_uis.erase(ui)
	_move_blur_uis.erase(ui)


## 开关：现在**显示着**就关掉，否则开出来。开/关两条路都走本文件的 open / close（含复用与摆位）。
## 指令写法：
##   UIInteract.toggle(preset_name="TestShow")            独立 UI（不写 target，只给预设名）
##   UIInteract.toggle(@self.parent.parent, "CloseButton") 挂在 target 下的某个预设 UI
## 为什么要有它：绑到一个键上时，"按一下开、再按一下关"是最常见的用法，写两条指令做不到
## （键状态只在"满足变化"时给一次，没法在同一个事件里判断该开还是该关）。
## 被谁用：状态层的按键快捷（如 Test 的 J / K）、想用一个按钮开关某个子 UI 的场合。
static func toggle(target: UIBase = null, preset_name: String = "") -> void:
	# 先按"开的时候会用哪个登记名"把实例找出来（找不到就是还没开过 ⇒ 走开）
	var ui: UIBase = null
	if preset_name == "":
		ui = target
	elif target != null:
		ui = _child_ui(target, preset_name)
	else:
		ui = RegSys.get_(UI_ROOT + preset_name) as UIBase
	if ui != null and ui.control != null and ui.control.is_visible_in_tree():
		close(ui)                                   # 正显示着 ⇒ 关它自己（隐藏，实例留着复用）
		return
	open(target, preset_name)


## 按"挂载点 + 预设名"取已登记的 UI —— 开（复用查找）与关（找要关的子 UI）共用的那把钥匙。
## 登记名就是 `RegSys.join(挂载点, 预设名)`（全项目唯一的一条寻址约定，登记与取件共用），
## 本函数只是它的取件形式。原来叫 UISys.get_child_ui：只有开/关用得到，就跟着搬到本文件了。
## 被谁用：open、close。
static func _child_ui(mount: UIBase, preset_name: String) -> UIBase:
	return RegSys.get_(RegSys.join(mount, preset_name)) as UIBase


## 现场造一个开启目标并登记：mount 为空 → 建预设自己那份挂 UI 根；有 mount → 挂到它下面。
## 挂到别处的一律用**深拷贝模板**（各实例互不影响："加按钮/加绑定"只改自己这一份）。
## 被谁用：open。
static func _build_open(preset: UIPreset, preset_name: String, mount: UIBase, extra: Dictionary = {}) -> UIBase:
	if mount == null:
		var ui: UIBase = preset.ui
		UISys.root.add_child(ui.build())
		# 独立 UI 的登记名 = `UI/预设名`（见 UISys 的登记名规则）：UI 的东西都挂在 `UI/` 这棵根下面，
		# 于是"这是 UI 还是别的东西"从名字上一眼分得清（将来角色 / 地图各有自己的根前缀）。
		UISys._register_tree(ui, UI_ROOT + preset_name)
		Msg.send_ui_create(ui)
		return ui
	var cfg: Dictionary = preset.config.duplicate(true)
	cfg.merge(extra, true)             # **build 之前**写好（见 open 里的说明）
	return mount.add_child_element(preset_name, preset.ui_name, cfg)


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
		ui.refresh("position")
		ui.control.show()


## ---------- 失焦关闭（点关 / 移开关，与"是不是菜单"无关）----------
## 为什么放在这里：能失焦关闭的只可能是**开出来的** UI（配置里的子元素不会被单独关），
## 所以候选在 open 那里登记，这里只做判定与关。
##
## 两张候选表：两套行为各一张（都由 open 登记、close 摘掉，只装"当前真的开着的那几个"）。
static var _blur_uis: Array[UIBase] = []        # close_on_blur：点关
static var _move_blur_uis: Array[UIBase] = []   # close_on_move：移开关


## 点关：遍历候选，指针不在它（或它的子孙元素/子孙 UI）上就关掉。
## 判定只要 parent 链，不需要"父子菜单链"这种登记：菜单链本身就是一棵子树
## （子菜单挂在触发它的菜单项下，见 UISys 文件头的挂载规则），所以鼠标在子菜单上时，
## 父菜单沿链就能找到自己 ⇒ 不关；父 UI 一 hide，链上的子 UI 也随可见性继承一起不可见。
## 被谁用：PointerDetect._process（每次"派发过事件"的下一次刷新里）。
static func close_blur_ui(hover_ui: UIBase) -> void:
	_close_outside(_blur_uis, hover_ui, false)


## 移开关：给"鼠标移上去自动展开"的 UI 用（多级菜单 hover 展开那种）。
## 判"在不在它上面"比点关**多算一层挂载点**：子菜单开在触发项旁边（不在触发项的矩形里），
## 指针通常还停在触发项上 ⇒ 只算自己的话，它一开出来就会被自己关掉。
## 被谁用：PointerDetect._process（本帧位移不为 0 时）。
static func close_move_blur_ui(hover_ui: UIBase) -> void:
	_close_outside(_move_blur_uis, hover_ui, true)


## 两套关闭行为共用的判定：候选里"指针已经不在上面"的先收集再关。
## with_mount = 连"它的挂载点（触发它的那个菜单项）"也算"在它上面"（移开关要，点关不要）。
## **边遍历边 close 会改到候选表**（close 里要摘掉候选），所以先收集再关。
## 被谁用：close_blur_ui、close_move_blur_ui。
static func _close_outside(uis_list: Array[UIBase], hover_ui: UIBase, with_mount: bool) -> void:
	var closing: Array[UIBase] = []
	for ui: UIBase in uis_list:
		# 尺寸还没算出来的先当它"还在指针下"：布局没跑时 get_global_rect() 是退化矩形，
		# 会被误判成"指针在外面"当场关掉（多级菜单"一开就没"就是这么来的）。
		# 反过来说：**尺寸被谁压成 0 的 UI 会永远跳过判定 ⇒ 永远关不掉**（free 子元素别挂进滚动容器，见 UI_Scroll）。
		var rect: Rect2 = ui.control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if _is_inside(ui, hover_ui):
			continue
		if with_mount and _is_inside(ui.parent, hover_ui):
			continue
		closing.append(ui)
	for ui: UIBase in closing:
		close(ui)


## 按被开 UI 自己的 config 记进对应的候选表（两套行为各一张，重复开同一个不会重复记）。
## 只记"开出来的"：配置里的子元素不会单独失焦关闭，不必进这两张表。
## 被谁用：open。
static func _reg_blur(ui: UIBase) -> void:
	if bool(ui.config.get("close_on_blur", false)) and not _blur_uis.has(ui):
		_blur_uis.append(ui)
	if bool(ui.config.get("close_on_move", false)) and not _move_blur_uis.has(ui):
		_move_blur_uis.append(ui)


## 指针是否在这个 UI 上：hover 沿 parent 链向上能找到 ui 即为"内"（所以它的子元素也算）。
## ui 传 null 时恒为 false（"没有挂载点"就是判断为不在）。
## 被谁用：_close_outside。
static func _is_inside(ui: UIBase, hover_ui: UIBase) -> bool:
	var cur: UIBase = hover_ui
	while cur != null:
		if cur == ui:
			return true
		cur = cur.parent
	return false
