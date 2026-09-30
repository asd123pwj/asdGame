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
##                 落地时把它的**注册名**记进 config["host"]（可读、能存盘）。
## 复用规则：按（挂载点 + 预设名）查登记名——**已存在就只显示 + 重新摆位，不重建控件**。
##
## 关闭行为两个开关（bool，默认 false = 不启用）：
##   close_on_blur = true  点关：有按键派发时，指针不在它上面就关 —— 右键菜单那种
##   close_on_move = true  移开关：指针一动，不在它（或其挂载点）上就关 —— hover 展开的子菜单那种
## **要在开的这一句直接给**（不是写进预设）：它们取决于"在哪开、为什么开"，与"这个预设长什么样"无关；
## 写进预设的话，每加一层子菜单就得记得抄一遍，漏一处那个 UI 就永远关不掉。
## 类型就是 bool，字符串/数字怎么变 bool 由指令系统按签名处理（CmdSys._coerce），这里不再自己认。
##
## **想顺手给这个 UI 改任意一项配置**：直接写键名就行（本函数有 `config` 参数 ⇒ 走 CmdSys 的
## 「任意配置键」约定：没对上参数名的命名参数都进 config）——不必为了某一项专门加个参数：
##   UIInteract.open(preset_name="RoleData", content_cmd="@Char/人类")
##   UIInteract.open(@host, "Editor", @host, host=@host, content_cmd="host.config", size=[310, 210])
## （`host` 是个例外：它要落成**注册名**再写进 config，得在这里转一手，所以留着专门参数。）
##
## 指令写法：
##   UIInteract.open(@self, "Menu", @self, close_on_blur=true)       面板右键 → 指针处开菜单（点别处关）
##   UIInteract.open(preset_name="RoleData")                        独立 UI → 开在配置声明的位置
##   UIInteract.open(@self, "MenuEdit", @self, close_on_move=true)   hover 展开的子菜单：挪开就收
##   UIInteract.open(@self, "Menu", @self, host=@self)                这个菜单改管自己（不是最外层窗口）
##   UIInteract.open(@self, "Menu", @self, host=@self.parent)         或者管别的 UI（取值链能算出来就行）
## 被谁用：Config/UI 里各预设的 "events"，以及外部想直接拿实例时。
## 返回：开出来的 UI（找不到预设/建不出来为 null）。
## 独立 UI（没有挂载点）的登记名前缀：`UI/预设名`（见 UISys 的登记名规则）。
const UI_ROOT: String = "UI/"


static func open(target: UIBase = null, preset_name: String = "", anchor: UIBase = null,
		close_on_blur: bool = false, close_on_move: bool = false, host: UIBase = null,
		config: Variant = null) -> UIBase:
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
	#   config —— **一份 config 片段**：写什么就覆盖预设里同名的那项。
	#             两种写法等价、可混用（见 CmdSys 的「任意配置键」约定）：
	#               · 直接写键名（推荐）：`content_cmd="host.config", size=[200, 0]`；
	#               · 或给一整份字典：`config={...}` / `config=某个静态变量`。
	#             直接写的键覆盖字典里同名的。
	#   注意**没有专门的 `content_cmd` 参数**：它就是一个普通配置键（元素自己从 config 里读它，
	#   见 UIBase.refresh / UIBase.target_path / UI_Editor._target_path），照「任意配置键」写就行。
	var extra: Dictionary = {}
	if config is Dictionary:
		extra = (config as Dictionary).duplicate(true)
	if host_name != "":
		extra["host"] = host_name
	var ui: UIBase = _child_ui(mount, preset_name)
	if ui == null:
		ui = _build_open(preset, preset_name, mount, extra)
	if ui == null:
		return null
	ui.config.merge(extra, true)             # 复用路径也写一次（"重开一次换个对象 / 换个管理对象"要改得动）
	# 合并来的配置要**让界面跟上**：写进 config 只是数据，子元素得重读一遍。
	# 典型场合：`UIInteract.open(@self, "Tip", @self, content="说明")` 的浮窗正文
	# ——预设里那个文字元素用 `content_cmd` 读外壳的 content，不刷就还是上一次那段。
	# extra 为空说明没改任何东西，不必白跑一趟。
	if not extra.is_empty():
		ui.refresh_tree()
	# 关闭行为：**总是按参数写**（默认 false = 不启用）。要哪种就在开的这一句写出来，
	# 预设里不再声明它——"在哪开、为什么开"只有开的那一句知道。
	ui.config["close_on_blur"] = close_on_blur
	ui.config["close_on_move"] = close_on_move
	_place(ui, anchor)
	_schedule_replace(ui, anchor)          # 尺寸是估的：下一帧真实尺寸出来再校一次（只一次，见该函数）
	# 排到最前——**只在宿主内**（`set_top_in_host`，见 UIInteract_SetTop 文件头）：
	# 悬停开出来的浮窗（Tip、hover 展开的子菜单）**不该把背后的宿主窗口整个提到前面**——鼠标只是
	# 掠过背后的菜单 B 上某个按钮，菜单 B 就跳到正在用的菜单 A 上面，A 就没法用了（实测困扰）。
	# 浮窗仍会被提到它宿主的那一层最前 ⇒ 照样压在自己的宿主内容之上、正常显示。
	# **点击那一下的窗口置顶**由 `PointerDetect.key` 走全局 `set_top` 负责，所以这里不提窗口不影响"点谁谁在前"。
	UIInteract_SetTop.set_top_in_host(ui)
	_reg_blur(ui)
	_just_opened.append(ui)                # 本帧刚开出来：失焦判定放过一次（见 _just_opened）
	# 告诉整棵子树"你被显示了"（元素据此开关自己的开销，如 UI_Status 订阅状态消息）——
	# **复用路径也走到这里**，所以"关掉再开"的元素也能收到（这条不发消息，见 UIBase.on_shown）。
	UIBase.dispatch_shown(ui)
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
	# 告诉整棵子树"你被隐藏了"（元素据此停掉自己的开销，见 UIBase.on_hidden）——
	# 与 open 那边的 dispatch_shown 成对；比"听 close 消息"更全（那样只盖得到被关的那一个）。
	UIBase.dispatch_hidden(ui)
	# 从两张失焦候选表里都摘掉（关过再开时 open 会重新登记 ⇒"显示着"与"在表里"始终一致）
	_blur_uis.erase(ui)
	_move_blur_uis.erase(ui)
	_drop_pending(ui)              # 关掉了就不必再跟着尺寸挪（也顺手把它的"尺子"摘掉，别一直持有实例）


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
## 登记名：挂在谁下面就是 `RegSys.join(挂载点, 预设名)`；**没有挂载点（独立 UI）就是 `UI/预设名`**
## （与 _build_open 登记的写法必须对上，否则"再开一次"会当成没开过、又建一份）。
## 本函数只是那条寻址约定的取件形式。原来叫 UISys.get_child_ui：只有开/关用得到，就跟着搬到本文件了。
## 被谁用：open、close。
static func _child_ui(mount: UIBase, preset_name: String) -> UIBase:
	if mount == null:
		return RegSys.get_(UI_ROOT + preset_name) as UIBase
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


## 指针类摆位的间隙：**0 = 浮窗左上角就在指针上**（与 Windows 菜单一致，也是"离鼠标最近"）。
## **别调大**：失焦判定（`close_blur_ui`）就是"指针不在浮窗上就关"——留出间隙等于让指针落在浮窗外面，
## 右键菜单"一开就关"就是这么来的（实测踩过）。往左 / 往上摆的那几个候选更要注意：要**压住指针 1px**
## 才算"指针在浮窗里"（`Rect2` 的右/下边是不含的）。
const POINTER_GAP := 0


## 按被开启 UI 自己的 config["open_at"] 摆位置并显示（Enums.OpenAt）：
##   CONFIG（默认，不写就是它）→ 摆回配置声明的 position（独立面板；被拖动过就回到初值）
##   POINTER                   → 开在**指针附近**（右键菜单、悬停提示浮窗）
##   ANCHOR_TOP_RIGHT          → 贴 anchor 的右上角顶点（多级菜单传触发它的那个菜单项）
##   ANCHOR_TOP_RIGHT_IN       → 贴 anchor **内部**的右上角（按自己宽度内缩；如面板的 "X" 按钮）
##   ANCHOR_BOTTOM_RIGHT_IN    → 贴 anchor **内部**的右下角（如缩放手柄）
##   ANCHOR_RIGHT_OUT          → 挂进 anchor **右侧外面**的那一列（外置按钮：关闭 / 两个手柄）——
##                               位置由宿主面板的角落容器整列维护（UI_Panel._corner_box），这里只负责显示
##   ANCHOR_NEAREST            → 贴 anchor **顶点、挑离指针最近的那个角**（=="ANCHOR_TOP_RIGHT + nearest"，
##                               悬停说明浮窗用它；见 Enums.OpenAt）
##   CENTER                    → 开在**屏幕正中**（按屏幕尺寸和自己的尺寸算——"占屏幕一块"的窗口，如角色数据看板）
##
## **摆位一律是"给一串候选、挑最不挡的"**（见 `_fit_pos`）：候选按"喜好顺序"排，**第一个能完整落在
## 屏幕里**的就用它；全都被屏幕挡掉 ⇒ 用"露出来的面积最大"的那个。
## **候选顺序"在哪弄"**：默认在 `Enums.OPEN_ORDER_POINTER / OPEN_ORDER_ANCHOR`
## （角名一律英文、与 `OpenAt` 里的叫法一致：`bottom_right` / `bottom_left` / `top_right` / `top_left`），
## 被开 UI 自己的 config 可以覆盖两样：
##   · `open_order` —— 一串角名（可只写前几个，如 `["top_left"]`），决定"先试哪个角"；
##   · "离指针最近优先" —— **`open_at = ANCHOR_NEAREST`**（贴锚点那种，推荐：一个"开在哪"只写一处），
##     或在别的策略上再补 `nearest: true`（如"指针旁也挑最近角"）；角名顺序只当平手时用。
## 于是两种常见尴尬自动消失：指针已贴着屏幕右下角 ⇒ 菜单翻到左上；子菜单贴着菜单项右侧而菜单已在
## 屏幕右边缘 ⇒ 翻到菜单项左边。
## **不需要"开出来再等几帧挪一下"**：`_want_size` 能在一帧内拿到"要多大"（还没排版就问元素自己）。
## 被谁用：open。
static func _place(ui: UIBase, anchor: UIBase) -> void:
	if ui.control == null:
		return
	var strategy: int = int(ui.config.get("open_at", Enums.OpenAt.CONFIG))
	if strategy == Enums.OpenAt.ANCHOR_RIGHT_OUT:
		# 外置按钮列：**不摆位**——它在宿主面板的角落容器里，位置由容器整列排（写了也会被容器覆盖，
		# 只白添一帧闪烁）。宿主不是面板时无处可排，也就停在配置值上（见 UIBase._anchor_free_child）。
		ui.control.show()
		return
	var size: Vector2 = _want_size(ui)
	# "离指针最近优先"两种写法（见函数头）：`ANCHOR_NEAREST` 这个策略本身就是它，
	# 别的策略则靠 `nearest: true` 补一条。
	var nearest: bool = bool(ui.config.get("nearest", false)) or strategy == Enums.OpenAt.ANCHOR_NEAREST
	var order: Array = ui.config.get("open_order", [])
	match strategy:
		Enums.OpenAt.CENTER:
			ui.show_at(_fit_pos([(UISys.screen_size() - size) * 0.5], size))
		Enums.OpenAt.POINTER:
			var names: Array = order if not order.is_empty() else Enums.OPEN_ORDER_POINTER
			ui.show_at(_fit_pos(_ordered(names, _pointer_positions(size), nearest, size), size))
		Enums.OpenAt.ANCHOR_TOP_RIGHT, Enums.OpenAt.ANCHOR_NEAREST, \
				Enums.OpenAt.ANCHOR_TOP_RIGHT_IN, Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN:
			if anchor == null or anchor.control == null:
				push_warning("UIInteract.open: 「%s」要求开在锚点角上，但锚点不可用，改在指针处开" % ui.name)
				ui.show_at(_fit_pos([InputSys.mouse_position], size))
				return
			var base: Array = Enums.OPEN_ORDER_ANCHOR if strategy != Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN \
				else Enums.OPEN_ORDER_POINTER
			var pick: Array = order if not order.is_empty() else base
			ui.show_at(_fit_pos(_ordered(pick, _anchor_positions(strategy, anchor.control.get_global_rect(), size),
				nearest, size), size))
		_:
			ui.refresh("position")
			ui.control.show()


## "指针附近"的四个候选（角名 → 坐标），见 Enums.OPEN_ORDER_POINTER。
## 往左 / 往上的那几个要**压住指针 1px**：`Rect2` 的右 / 下边不含 ⇒ 正好贴着边等于"指针不在浮窗里"
## ⇒ 会被失焦判定当场关掉（见 POINTER_GAP 的说明）。
## 被谁用：_place。
static func _pointer_positions(size: Vector2) -> Dictionary:
	var p: Vector2 = InputSys.mouse_position
	var px: float = p.x - size.x + POINTER_GAP + 1.0
	var py: float = p.y - size.y + POINTER_GAP + 1.0
	return {
		"bottom_right": p + Vector2(POINTER_GAP, POINTER_GAP),
		"bottom_left": Vector2(px, p.y + POINTER_GAP),
		"top_right": Vector2(p.x + POINTER_GAP, py),
		"top_left": Vector2(px, py),
	}


## "贴锚点"的四个候选（角名 → 坐标）：IN 版往锚点**内部**缩，顶点版贴着锚点四角**外面**。
## 被谁用：_place。
static func _anchor_positions(strategy: int, rect: Rect2, size: Vector2) -> Dictionary:
	# **顶点版**（贴锚点四角**外面**）只有这两个策略：`ANCHOR_TOP_RIGHT`（多级菜单）与 `ANCHOR_NEAREST`
	# （悬停说明：同样贴锚点外，只是候选按"离指针最近"排）；其余（两个 `*_IN`）都往锚点**内部**缩。
	# **别写"不等于 ANCHOR_TOP_RIGHT 就算 inside"**：那样新加一个顶点版策略会**静默**变成内部版
	# （加 ANCHOR_NEAREST 时实测踩到：浮窗贴到锚点里侧去了）。
	var inside: bool = strategy != Enums.OpenAt.ANCHOR_TOP_RIGHT \
		and strategy != Enums.OpenAt.ANCHOR_NEAREST
	var x_right: float = rect.end.x - size.x if inside else rect.end.x
	var x_left: float = rect.position.x if inside else rect.position.x - size.x
	var y_top: float = rect.position.y
	var y_bottom: float = rect.end.y - size.y if inside else rect.end.y
	return {"bottom_right": Vector2(x_right, y_bottom), "bottom_left": Vector2(x_left, y_bottom),
		"top_right": Vector2(x_right, y_top), "top_left": Vector2(x_left, y_top)}


## 把"角名 → 坐标"排成候选序列：按 `names` 的顺序；`nearest` 时改成**按"离指针最近"排序**
## （用候选矩形中心算距离；`names` 里的先后只当平手时的次序）。`names` 里没提到的角补在末尾。
## 被谁用：_place。
static func _ordered(names: Array, positions: Dictionary, nearest: bool, size: Vector2) -> Array:
	var out: Array = []
	for n in names:
		if positions.has(n) and not out.has(positions[n]):
			out.append(positions[n])
	for n in positions.keys():
		if not out.has(positions[n]):
			out.append(positions[n])
	if nearest:
		var p: Vector2 = InputSys.mouse_position
		var half: Vector2 = size * 0.5
		out.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return (a + half).distance_squared_to(p) < (b + half).distance_squared_to(p))
	return out


## "这个 UI 要占多大"：**优先用控件自己的尺寸**（已经排过一次的那版，通常只差一行）；
## 哪一维还是 0（还没排过版）才去问元素自己（`_content_size`）。
## 为什么不直接信 `_content_size`：**在建好那一刻它是"高估"的**——折行文字那时还不知道自己多宽，
## 会按"很窄"去估行数（实测：菜单真实 108、它报 252，反而把浮窗摆得更远）；控件自己的尺寸是
## 引擎按实际宽排过的，近得多。剩下那点误差（折行高的异步更新 ⇒ 常差一行）由 `_schedule_replace`
## 在下一帧用真实尺寸补一刀。
## 被谁用：_place。
static func _want_size(ui: UIBase) -> Vector2:
	var s: Vector2 = ui.control.size
	if s.x <= 0.0 or s.y <= 0.0:
		s = s.max(ui._content_size())
	return s


## 定位置后挂一把尺子：**刚开出来的这几帧里**，尺寸一变就按真实尺寸重摆一次（见 `REPLACE_WINDOW_MS`）。
## 为什么需要：打开那一帧的尺寸只能是估的（见 `_want_size`），估小一点就会"贴着屏幕边开出去"或
## "该翻边没翻"；尺寸落定后重摆就正了——**只错一帧、只挪一点，肉眼几乎看不出**，比"一开就在屏幕外"好。
## **为什么不是"只校一次"**：尺寸不是一次就到位——实测菜单是 84 → **252（排版中途的虚高）** → 108，
## 只跟第一拍（252）会摆得比真实需要的更远（偏高 144px）。所以在"刚开出来"的这段时间里**每变一次跟一次**。
## **盯控件的 `resized`、不盯 `SceneTree.process_frame`**：开机那一批 UI 是在 `_ready` 里开的，那时
## **UI 根还没挂进场景树**（`Sys._ready` 用的是 `add_child.call_deferred`）⇒ 走 `get_tree()` 会拿到 null
## 并抛 "Parameter data.tree is null"，还把 `open` 的后续（置顶 / 失焦登记 / dispatch_shown）一起打断。
## 控件自己的信号不需要树，任何时候都能连。
## 退化尺寸那一拍跳过（排版中途会发"尺寸瞬时为 0"的 resized，用那一拍摆位反而更偏），等下一次。
## **只对"自适应摆位"的策略做**：`CONFIG`（摆回配置里的 position）与 `ANCHOR_RIGHT_OUT`（角落容器整列排）
## 不该被挪——前者可能已经被拖动过，后者位置不归这里管。
## 被谁用：open。
static func _schedule_replace(ui: UIBase, anchor: UIBase) -> void:
	var strategy: int = int(ui.config.get("open_at", Enums.OpenAt.CONFIG))
	if strategy == Enums.OpenAt.CONFIG or strategy == Enums.OpenAt.ANCHOR_RIGHT_OUT:
		return
	if ui.control == null:
		return
	if _pending.has(ui):                       # 同一个 UI 又开了一次：先撤掉上一把尺子
		_drop_pending(ui)
	var cb: Callable = _replace_once.bind(ui)
	_pending[ui] = [anchor, cb, Time.get_ticks_msec()]
	ui.control.resized.connect(cb)


## 摘掉某元素的"待校正尺子"（断开信号 + 忘掉记录）——**断开是必须的**，否则 `_pending` 会一直持有它
## （元素就永远释放不掉），而且它下次再开时会被误判成"已经有尺子了"。
## 被谁用：_schedule_replace（重开时）、_replace_once（过期时）、close（关掉时）。
static func _drop_pending(ui: UIBase) -> void:
	var entry: Array = _pending.get(ui, [])
	if entry.is_empty():
		return
	if ui.control != null and ui.control.resized.is_connected(entry[1]):
		ui.control.resized.disconnect(entry[1])
	_pending.erase(ui)


## "刚开出来"的这段时间（毫秒）：这期间尺寸一变就重摆（过了就摘掉尺子，之后内容变化不再挪浮窗）。
const REPLACE_WINDOW_MS := 300
## 待校正的元素：`ui -> [anchor, 连接用的 Callable, 开出来的时刻]`（要能断开，所以 Callable 留着）。
static var _pending: Dictionary = {}
## **本帧刚开出来的 UI**：失焦判定放过它们一次（见 `_close_outside`）。
## 为什么：浮窗尺寸/位置在开出来的那一帧还没落定，"指针在不在它上面"此刻判不出准头——
## 右键菜单"一开就关"就有这一半原因（实测）。它也不可能在这一帧被"点别处"关掉（那一帧指针没动过）。
static var _just_opened: Array[UIBase] = []


## 清掉"本帧刚开出来"的名单——**每帧刷新一次**（由 PointerDetect._process 的尾巴调，那次刷新末尾本就是
## 失焦判定的收尾处）。不清理的话第一帧之后它还在名单里 ⇒ 那个浮窗**永远**跳过失焦判定（关不掉）。
static func clear_just_opened() -> void:
	_just_opened.clear()


## `_schedule_replace` 的那一刀：按真实尺寸重摆一次（尺寸还会再变就留着尺子，过了时限才摘）。
static func _replace_once(ui: UIBase) -> void:
	var entry: Array = _pending.get(ui, [])
	if entry.is_empty():
		return
	var anchor: UIBase = entry[0]
	if ui.control == null:
		_drop_pending(ui)
		return
	if Time.get_ticks_msec() - int(entry[2]) > REPLACE_WINDOW_MS:
		_drop_pending(ui)
		return                                  # 已过"刚开出来"那段：不再跟着挪（用户可能已经在用了）
	if ui.control.size.x <= 0.0 or ui.control.size.y <= 0.0:
		return                                  # 退化尺寸那一拍不算数（排版中途会发），等下一次
	if ui.control.visible:
		_place(ui, anchor)


## 在候选位置里挑一个（候选**已按喜好排序**）：
##   · **第一个"能完整落在屏幕里"的**就选它——所以"首选右下、右下放不下就左下"是这样表达的；
##   · 全都被屏幕挡掉（浮窗比屏幕还大之类）⇒ 选"与屏幕相交面积最大"的那个 = **被挡得最少**。
## **一帧算完**：只有几次矩形求交（候选最多 4 个），不需要跨帧试探。坐标取整（像素风）。
## 被谁用：_place（所有策略）。
static func _fit_pos(candidates: Array, size: Vector2) -> Vector2:
	var screen: Rect2 = Rect2(Vector2.ZERO, UISys.screen_size())
	var best: Vector2 = candidates[0]
	var best_vis: float = -1.0
	for c: Vector2 in candidates:
		var r: Rect2 = Rect2(c, size)
		var vis: float = r.intersection(screen).get_area()
		if vis >= r.get_area() - 0.5:
			return c.floor()                     # 完整可见 ⇒ 就它
		if vis > best_vis:
			best_vis = vis
			best = c
	return best.floor()


## ---------- 失焦关闭（点关 / 移开关，与"是不是菜单"无关）----------


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
		if _just_opened.has(ui):
			continue                       # 本帧刚开出来：这一帧不判（尺寸/位置还没落定，见 _just_opened）
		# 尺寸还没算出来的先当它"还在指针下"：布局没跑时 get_global_rect() 是退化矩形，
		# 会被误判成"指针在外面"当场关掉（多级菜单"一开就没"就是这么来的）。
		# 反过来说：**尺寸被谁压成 0 的 UI 会永远跳过判定 ⇒ 永远关不掉**（free 子元素别挂进滚动容器，见 UI_Panel）。
		var rect: Rect2 = ui.control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if _in_subtree(ui, hover_ui):
			continue
		if with_mount and _in_subtree(ui.parent, hover_ui):
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


## "指针在不在这个 UI 上"由基类的 `UIInteractBase._in_subtree` 提供（与浮窗那套是同一条判据，
## 所以只留一份：一样的代码写两遍，改一处忘一处早晚出事）。
