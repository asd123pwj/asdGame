class_name UIBase
extends BaseClass
## UI 元素基类（设计见 Script/UI/UI.md）。
## extends BaseClass，内部持 control: Control（不直接继承 Control）。
## 指针输入由 PointerDetect 用 InputSys 检测命中后回调本对象（不用引擎 gui_input）。
## 交互**不用开关**（draggable/closeable 等已移除），而是"事件→指令"：
## config["events"] 是 [事件名, 指令串] 的列表，事件发生即发送对应指令。
## 事件名就是**状态名**（如 "Pointer 1 Hold"）：UI 不关心键位，键位只在状态层（statuses 的 keys）配置；
## hover 变化不对应任何状态，用 QName.pointer_enter / QName.pointer_exit。
## 占位符解析与交互实现都在 UIInteract（UIBase 只存"何时发什么指令"）；
## 登记与寻址在 UISys（登记表 + 登记名规则）；**开启**在 UIInteract_OpenClose.open
## （**全项目唯一的开启入口**，指令形式 `UIInteract.open`）。
## 显示内容就是 config["content"]（**没有同名成员变量**），由子类 refresh() 刷到控件上。

## 元素名：登记名的一段（独立 UI 就是预设名，子元素就是配置里写的名字）。
## 被谁用：UISys._register_tree / find_name（拼登记名）、各处的警告文案。
var name: String = ""

## 背景图九宫格的边距**每张图各自给**：写在 config["background_slice"]（不写 = 全局默认
## `SysCfg.ui_background_slice`；要"整张拉伸"就显式写 0）——不同底图的圆角不一样，切多切少都会变形（见 _make_background）。
## "找当底的 stylebox 槽"的顺序放全局参数里：SysCfg.ui_background_slots（Config/SystemConfig.gd）。
## 本元素的配置（见 Config/UI/）。公共属性：position/size/content/children/events/visible/free，
## 各子类另有自己的（如菜单的 open_at / close_on_blur）；收起/展开那两个键（父元素的 collapsed、
## 子元素自己的 collapse_keep）由交互 UIInteract.fold 读（见 Interact/UIInteract_Fold.gd）——
## 本类**只在 _fit_size 里看一眼 `collapsed`**：收起时**宽高都让给内容**（窗口缩成标题文本宽那么小，见那儿）。
## 被谁用：_apply_config、_build_children、on_event、UISys._place（读 open_at）。
var config: Dictionary = {}

## `content_cmd`（查看项的指令版本）生效时，字面值存在这儿（`_` 开头 = 元素内部影子键，UI_Editor 不显示）。
## 于是"指令版本撤了"能回到字面值，见 refresh。
const CONTENT_LITERAL_KEY := "_content_static"
## 真正的引擎控件（本元素外观的根，子节点也挂在它下面）。
## 被谁用：UISystem（挂载）、PointerDetect._ui_at（命中矩形）、UIInteract 各指令、UISys._place。
var control: Control

## 显示内容：指明该 UI 展示什么（文本/多行文本/纹理路径…由子类解释）。
## **就是 config["content"] 这一个键，不另设成员变量**——一份数据一处真相，不会两边不一致。
## 改内容 = `Utils.write "@self.config.content" 新值`，再在**下一条**接刷新（`self.refresh`）；
## 子类 refresh() 负责把它刷到控件上（见 UI.md 的"改了什么就刷什么"）。
## 为什么不做成属性 set 自动刷：那样要拦截的就不止 content 一项（config 里还有 events/size/…），
## 而 config 是 Dictionary、拦不了写入（要拦得把它换成带 _set/_get 的对象，读点太多、得不偿失）。

## 挂载对象（父 UI）：组装子元素时由父元素注入，即指令里 `@self.parent` 的指向。
## 被谁用：_build_children / add_child_element（注入）、指令系统（`@self` 链上的 .parent）、
##         on_event（事件冒泡）、UIInteractBase._in_subtree（判"指针是否在这个 UI 的子树里"）。
var parent: UIBase = null

## 挂在 control 上的 meta 键：控件 → UIBase 反查（指针命中沿控件树走，见 PointerDetect._ui_at）。
## 被谁用：build()（写）、PointerDetect._hit_in（读）。
const META_UI := "ui_base"

## 子元素：build() 按 config["children"] 组装，每项 [child_name, ui_class, child_config]。
## 被谁用：_build_children / add_child_element（追加）、UISys._register_tree（递归登记）、
##         _free_box 的选择依据（在 add_child_element 里读 free 配置）。
var children: Array[UIBase] = []


## 构造：只记名字与配置，控件在 build() 里才建。
## 被谁用：UIPreset.create_element（唯一的实例化工厂）→ UIPreset._get_ui_by_name。
func _init(name_: String = "", config_: Dictionary = {}) -> void:
	name = name_
	config = config_


## 生成控件树并组装子元素，返回 control（供 UISystem 挂载）。
## 顺序不能换：建控件 → 应用配置 → 刷内容 → 建子元素 → 补尺寸（子元素建完才知道内容多大）。
## 建完把"我自己"挂在 control 的 meta 上（META_UI）：指针命中是**沿控件树**走的
## （见 PointerDetect._ui_at），走到一个没挂 meta 的内部控件（容器的 PanelContainer/VBox、
## 文本内部的 Label 之类）就往上取最近的这个元素。
## 被谁用：UIInteract_OpenClose._build_open（独立 UI 与寄主型都走它）、_build_children / add_child_element（子元素）。
func build() -> Control:
	control = _create_control()
	control.set_meta(META_UI, self)
	_apply_config()
	refresh()
	_build_children()
	_fit_size()
	return control


## size 配置里为 0 的那一维，按"内容最小尺寸"补足（要等子元素建完才知道内容多大）。
## 于是 [宽, 0] = 宽固定、高随内容；[0, 0] = 完全由内容决定。
## 注意必须补：控件尺寸为 0 时 get_global_rect() 是退化矩形，
## PointerDetect 永远命中不到它（菜单这类"宽固定、高随内容"的面板就靠这一步）。
## **补完还把结果发布成控件的最小尺寸**（custom_minimum_size）：本元素的根控件是普通 Control，
## 它自己不汇总内容最小尺寸，而"面板套面板"（容器里的 UI_Panel，如可折叠分组）要靠这个最小尺寸
## 才能往外撑——不发布的话内层面板在父容器眼里高度就是 0，整棵子树都长不出来
## （实测：嵌套分组的高度一直停在标题那一点，只有被容器排到才动一下）。
## 被谁用：build()；UI_Panel 另在 _panel.minimum_size_changed 时重调
##         （建时还没进树、字体主题问不出来，内容多大要等容器排完版才知道）。
## 登记完成回调：**默认什么都不做**，需要"等自己有名字（登记好）之后再做点事"的元素覆写它。
## 什么时候被叫：UISys._register_tree 给本元素登记好名字之后（一次；重开 / 追加子元素会再登记也就再叫）。
## 谁在用：UI_Editor（要按源字典铺内容，而铺出来的子元素登记要拿父级名字，所以得等这一步）。
func on_registered() -> void:
	pass


## 被显示 / 被隐藏回调：**默认什么都不做**，需要"知道自己被开出来 / 被关掉"的元素覆写它。
## 什么时候被叫：`UIInteract.open` 摆好位、显示之后叫 `on_shown`；`UIInteract.close` 隐藏之后叫 `on_hidden`。
## **整棵子树都会收到**（先自己后子元素，元素自己铺出来的子孙照样收到）——见 dispatch_shown / dispatch_hidden。
## 为什么要有它：元素可能需要"随着'看得见没'开关自己的开销"（如 UI_Status 只在这时订阅 / 退订那些状态消息）；
## 光靠 close 那条消息不够——**重开一个已存在的 UI 是"复用 + 显示"，不发消息**，只有这个回调两条路都盖得到。
## 谁在用：UI_Status（开着就订状态消息、关掉就退订）。
func on_shown() -> void:
	pass


func on_hidden() -> void:
	pass


## 通知"某棵 UI 被显示了 / 被隐藏了"：先叫自己，再递归每个子元素（见 on_shown / on_hidden）。
## 被谁用：UIInteract_OpenClose.open（显示之后）、close（隐藏之后）。
static func dispatch_shown(ui: UIBase) -> void:
	_dispatch_life(ui, true)


static func dispatch_hidden(ui: UIBase) -> void:
	_dispatch_life(ui, false)


## dispatch_shown / dispatch_hidden 的实现（别在别处再写一份递归）。
static func _dispatch_life(ui: UIBase, shown: bool) -> void:
	if ui == null:
		return
	if shown:
		ui.on_shown()
	else:
		ui.on_hidden()
	for child in ui.children:
		_dispatch_life(child, shown)


func _fit_size() -> void:
	if control == null:
		return          # 已被移除的动态 UI（见 clear_children）：没有控件可摆，晚到的信号直接忽略
	var collapsed: bool = bool(config.get("collapsed", false))
	# **收起时宽高都让给内容**（`collapsed` 见 UIInteract_Fold）：收起后只留 `collapse_keep` 的元素
	# （标题条），整个面板缩成"标题文本宽 + 一圈边距"那么小——而不是还占着配置里那整块宽
	# （如 `size_ratio` 的 3/4 屏）：那样收起来仍是一条大底，看着像没收干净（实测踩过）。
	# 宽度也走内容而非 `size_ratio`：标题是 `fill_width`，它的"最小宽"就是文本宽，于是面板宽 =
	# 文本宽 + 边距，标题条正好等于文本宽（见 UIInteract_Fold.title_item 的 fill_width）。
	# 不收起 ⇒ 按配置尺寸（`size_ratio` / `size`），那一维写 0 才走内容。
	var want: Vector2 = _content_size() if collapsed else _config_size()
	# **挂在容器（Container）里的元素不自己写 size**：宽高由容器排版时分配，自己再写一遍只会跟容器
	# 打架——容器分 433、自己缩回 432，段里恰好压在折行边界上的标题就在"1 行 / 2 行"之间无限翻转
	# （段最小高 204↔228 ⇒ 格子滚动条反复出现/消失 ⇒ 一帧永远排不完版 = 整个游戏卡死，实测踩过）。
	# 容器只需要 `custom_minimum_size`（它在，容器自然会把尺寸分配到位）；
	# 不在容器里的（顶层窗口挂 CanvasLayer、free 挂 Overlay、网格格挂 Grid）才自己写 size。
	var in_container: bool = control.get_parent() is Container
	if want.x > 0.0 and want.y > 0.0:
		control.custom_minimum_size = want
		if not in_container:
			control.size = want
		return
	var need: Vector2 = _content_size()
	var out: Vector2 = Vector2(want.x if want.x > 0.0 else need.x, want.y if want.y > 0.0 else need.y)
	# **宽度由容器给**的元素（见 `_width_from_parent`）：只报高度，**一点不碰宽**——
	# 报了宽（哪怕报 0）都会把控件钉在那个宽度上，容器再排也拉不开
	# （实测：文本被压成 1px、折了 61 行）。宽度由容器在它自己排版时赋给。
	# `_keep_min_width` 为真时（"顶满"的标题栏）自己那份宽仍报出去当**最小宽**：容器更宽就顶满、更窄也不会折碎。
	if _width_from_parent() and want.x <= 0.0:
		control.custom_minimum_size = Vector2(out.x if _keep_min_width() else 0.0, out.y)
		if not in_container:
			control.size.y = out.y
		return
	control.custom_minimum_size = out
	if not in_container:
		control.size = out


## 本元素的**宽度由容器给**吗（自己不报宽、也不设 `size.x`，由容器排版时赋）？
## 默认 false = 宽度按"配置想要 / 内容需要"自己定（绝大多数元素）。
## 覆写者：UI_Label（在"以面板为准"的环境里，或自己配了 `wrap: true` / `fill_width: true`）——
## 那时宽度归面板，文本只负责"照给到的宽折行、算出该多高"。见 `_fit_size` 里那一支。
func _width_from_parent() -> bool:
	return false


## 宽度交给容器时，**自己那份宽还算不算数**（算 = 报出去当最小宽，容器更宽就顶满）。
## 默认 false = 完全不占宽（面板有多宽由**别人**定：折行正文 `wrap` 就是这样）。
## 覆写者：UI_Label（配了 `fill_width` 的元素——窗口标题栏要"顶满整块面板"，又不能让面板缩到只剩边距）。
## 被谁用：_fit_size（宽度交给容器那一支）。
func _keep_min_width() -> bool:
	return false


## "配置想要多大"（两维都为 0 = 由内容决定）。两种写法，**`size_ratio` 优先**：
##   · `config["size"]`      = [宽, 高] 像素（写 0 的那一维随内容走）；
##   · `config["size_ratio"]`= [宽比, 高比] **相对屏幕**（见 `UISys.screen_size`）——
##     写它就不用跟着分辨率改数字：`[0.75, 0.75]` 在 1920×1080 上是 1440×810、
##     在 2560×1440 上是 1920×1080（"占屏幕多少"这件事本来就跟屏幕挂钩）。
## **不要读 control.custom_minimum_size 当"配置想要多大"**：那个值会被 _fit_size 覆盖成
## "内容实际多大"，于是分不清"配置要什么"和"内容给了多少"（宽固定、高随内容这种就废了）。
## 被谁用：_fit_size、reapply（"应用尺寸"只此一处）。
func _config_size() -> Vector2:
	var ratio: Variant = config.get("size_ratio")
	if ratio is Array and (ratio as Array).size() >= 2:
		var area: Vector2 = UISys.screen_size()
		return Vector2(area.x * float((ratio as Array)[0]), area.y * float((ratio as Array)[1]))
	var s: Variant = config.get("size")
	if not (s is Array):
		return Vector2.ZERO
	var arr: Array = s
	if arr.size() >= 2:
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2.ZERO


## 内容本身需要多大（默认取控件的最小尺寸）。
## 容器类要覆写：**普通 Control 不会汇总子元素的最小尺寸**，
## 这时必须问内部真正的容器（它才带着边距 + 内容），否则 size 里为 0 的那一维会补成 0，
## 得到一个高度为 0 的退化矩形（画不出来，也命中不到）。
## 被谁用：_fit_size。覆写者：UI_Panel。
func _content_size() -> Vector2:
	return control.get_combined_minimum_size()


## 宽度上限（**像素**）：`config["max_width"]`（像素）与 `config["max_chars"]`（**字符数**）取小的那个；
## 都没写 = 0 = 不限。
## **为什么能按字符数说**：默认字体是「霞鹜文楷等宽」这类**等宽**字体，**中文 = 数字/英文的两倍宽**
## （宽窄是向字体量的，见 `_half_width`）⇒ 一个"字符" = 半个中文宽。比例字体里这个关系不成立
## （那时按字符数配宽度会不准），所以是"量出来再乘"，不是假设。
## 被谁用：UI_Label / UI_Input（"这一栏有多宽"的唯一定义处，别在子类里各写一份）。
func _max_width_px(ctrl: Control) -> float:
	if ctrl == null:
		return 0.0
	var px: float = float(config.get("max_width", 0))
	var chars: int = int(config.get("max_chars", 0))
	if chars > 0:
		var by_chars: float = float(chars) * _half_width(ctrl)
		px = by_chars if px <= 0.0 else minf(px, by_chars)
	return px


## 一个"半角字符"按多宽算：**半角（"0"）与 全角÷2 取大的那个**——都向字体量，不猜。
## 为什么取大的：中文按 2 个字符算，而"2 个半角"与"1 个全角"在不同字体里**不一定一样宽**
## ——实测「霞鹜文楷等宽」20 号下是 半角 10px / 全角 20px（正好 2:1）；换成比例字体就可能不是，
## 那时取大的那个才不会把字挤掉。
## 被谁用：_max_width_px。
static func _half_width(ctrl: Control) -> float:
	var font: Font = ctrl.get_theme_font("font")
	var fs: int = ctrl.get_theme_font_size("font_size")
	var half: float = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var full: float = font.get_string_size("中", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return maxf(half, full / 2.0)


## 一行有多高：**字体的字高 + 主题的行距**——都是问出来的，不写死数字
## （换字体 / 换字号 / 换主题之后它自己就变了）。TextEdit 与 Label 的行高规则一致
## （实测：字高 24 + 行距 4 = 28，与引擎给两行文字排出来的高一致）。
## 被谁用：UI_Input._text_height / UI_Label._text_height。
static func _row_height(ctrl: Control) -> float:
	return ctrl.get_theme_font("font").get_height(ctrl.get_theme_font_size("font_size")) \
		+ float(ctrl.get_theme_constant("line_spacing"))


## 虚接口：子类生成自身外观控件。
## 被谁用：build()。实现者：UI_Panel / UI_Label / UI_Image / UI_Input。
func _create_control() -> Control:
	return Control.new()


## 刷新界面：**不传 key = 把 config 里认识的项全部同步**（应用到控件）；
## 传 key = 只刷那一项。子类覆写时先 `super.refresh(key)`，再处理自己新增的键。
## 基类只管公共的 visible / position；**content 由各子类自己读 config["content"] 刷**（见实现者）。
## 认识的公共键：visible（可见性）、position（摆放位置）。
## **position 只有显式 `refresh("position")` 才刷**：不传 key 的"全刷"不碰摆放——
## 拖动/摆位是运行时的临时偏离，不该被一次普通刷新拽回 config 里那个位置。
## **只改了一项就传那一项**（`@self.refresh("content")`）——跟"改了什么刷什么"对上，也省掉别的项的无谓同步；
## 不传 key 的"全刷"留着给"一次改了好几项 / 不确定"的场合。
## 实现者：UI_Label / UI_Image / UI_Input（各自的键见它们的 refresh）。
## 被谁用：build()（全部）、配置里改完 config 后紧跟的 `@self.refresh("content")`、
##         UIInteract_OpenClose._place（position）。
func refresh(key: String = "") -> void:
	# **查看项**：`content_cmd`（显示内容的**指令版本**）有值就用它——于是"显示什么"随时算得出来
	# （指向别的 UI / 某个角色的数据都行），而不只是配置里写死的那个字面值。
	# **优先级：`content_cmd` > `content`**（两边都写以指令版本为准：它是"活的"，content 是初值 / 兜底）；
	# 指令版本算不出来（路径写错 / 那个东西不在）就**保持 content 原样**，不把界面刷空。
	# 解析结果直接写回 config["content"]：各元素的 refresh 照旧只读 content（它们不用知道有这一项）。
	if key == "" or key == "content":
		var cmd: String = str(config.get("content_cmd", ""))
		if cmd != "":
			# **`@self` = 写这条 content_cmd 的元素**：refresh 多数不在事件派发里跑（不像配置 events），
			# 那时指令系统记的"当前元素"是上一次派发留下的（甚至没有）⇒ 这里临时指成自己，
			# 让 content_cmd 里 `@self.parent.config.content` 这种路径稳定可算（用完还原，不污染别处）。
			var prev_ui: Object = CommandParser.event_ui
			CommandParser.event_ui = self
			var got: Array = CommandParser.read(cmd)
			CommandParser.event_ui = prev_ui
			if bool(got[0]):
				if not config.has(CONTENT_LITERAL_KEY):
					# 第一次盖掉字面值前先把它存起来（`_` 开头 = 内部影子键，编辑器不显示它）：
					# 于是"指令版本撤了"还能回到原来那个字面值，而不是把界面的显示内容弄丢。
					config[CONTENT_LITERAL_KEY] = config.get("content")
				config["content"] = got[1]
		elif config.has(CONTENT_LITERAL_KEY):
			config["content"] = config[CONTENT_LITERAL_KEY]
			config.erase(CONTENT_LITERAL_KEY)
	if (key == "" or key == "visible") and control != null and config.has("visible"):
		control.visible = bool(config["visible"])
	if key == "position" and control != null and config.has("position") and config["position"] is Array:
		var p: Array = config["position"]
		if p.size() >= 2:
			control.position = Vector2(float(p[0]), float(p[1]))


## 刷新**本元素与整棵子树**：外壳的 config 被外部改过之后让界面跟上。
## 与 refresh 的分工：refresh 管"自己这一项那项怎么刷"（配置里的常规用法，一项一项刷）；
## 这里是"刚合并了一整份配置"的收尾——子元素可能读外壳的配置（如浮窗正文写
## `content_cmd = "@self.parent.config.content"`），不往下刷它还停在上一次的内容。
## 被谁用：UIInteract_OpenClose.open（临时配置合并完）。
func refresh_tree() -> void:
	refresh()
	for child in children:
		child.refresh_tree()


## **这个 UI 该看哪个对象**（"查看项"的读取规则；返回路径 / 引用，空串 = 没指定）：
##   1. `content_cmd`：自己的，再**沿外壳往上**找第一处（`open(..., content_cmd="…")` 通常写在外壳那层，
##      一次就对整块生效，元素不必知道套了几层）；
##   2. 自己的 `fallback_key` 配置（如 `char` = "没指定时看谁"；不传就不看这一层）；
##   3. 都给不出 ⇒ 空串（由调用方铺提示——本函数不猜、也不兜底到别人的东西）。
## **不认 `content` 字面值**：那多半是"这个 UI 显示的文字"，不是"对象在哪"（`UI_Editor` 有自己的判断，
## 它还要认 `content` 字面值和 `host.` 相对写法，见它的 _target_path）。
## 被谁用：UI_Status / UI_Shortcut（"看哪个角色"）。
func target_path(fallback_key: String = "") -> String:
	var cmd: String = str(config.get("content_cmd", ""))
	if cmd == "":
		var up: UIBase = parent
		while up != null:
			var c: String = str(up.config.get("content_cmd", ""))
			if c != "":
				cmd = c
				break
			up = up.parent
	if cmd != "":
		return cmd
	return str(config.get(fallback_key, "")) if fallback_key != "" else ""


## 按 `target_path()` 取那个对象（**只读**，不改任何东西——同 CommandParser.read）。
## 读不到 / 类型不对都给 null，由调用方铺提示。
## 被谁用：UI_Status / UI_Shortcut（`target_object("char") as Character`）。
func target_object(fallback_key: String = "") -> Object:
	var path: String = target_path(fallback_key)
	if path == "":
		return null
	var got: Array = CommandParser.read(path)
	return (got[1] as Object) if bool(got[0]) else null


## 摆到指定**屏幕坐标**并显示（按 open_at 策略开的 UI 用，见 UISys._place）。
## 位置换算成"挂载点坐标系"的 position：
##   - 不用 set_global_position——它按"当前全局变换求逆"算，重复摆会跟旧 position 复合，越摆越偏；
##   - 也不设 Control.top_level——那会让元素不再继承父级可见性（父级 hide 后它还留在屏幕上、也还能被命中）。
## 被谁用：UISys._place（POINTER / ANCHOR_TOP_RIGHT 两种策略）。
func show_at(pos: Vector2) -> void:
	if control == null:
		return
	var box: Control = control.get_parent() as Control
	var origin: Vector2 = box.get_global_rect().position if box != null else Vector2.ZERO
	control.position = pos - origin
	control.show()


## 清掉本元素**运行期铺出来**的子元素（整排摘掉，见 remove_child_element）。
## 给"自己按数据铺内容的元素"重铺时用（见 UI_Status.reload / UI_Editor.rebuild）：
## 铺出来的子元素都登记过，直接 queue_free 会在登记表里留下指向"已经没了的东西"的名字
## （见 RegSys.unregister 的说明）。
## 被谁用：UI_Status.reload、UI_Editor.rebuild。
func clear_children() -> void:
	for child in children.duplicate():
		remove_child_element(child)


## 摘掉一个子元素（递归摘注册名 → 释放控件 → 从 children 摘掉）。不在 children 里就什么都不做。
## 只重铺其中一块时用它（如 UI_Status 收到状态变化，只重铺那一段）。
func remove_child_element(ui: UIBase) -> void:
	if ui == null:
		return
	children.erase(ui)
	_remove_subtree(ui)


## **原地换掉**一个子元素：摘掉 `old` → 按参数新建一个 → **放回它原来的位置**（children 里与容器里的位次都不变）。
## 只重铺其中一块时用它（见 UI_View._refresh_section）：直接"摘掉再加"会把那块排到**最底下**，
## 于是"状态一变，那一行就跳到最后"（实测踩过——面板里的次序是用户看着的东西，不能自己动）。
## `old` 为 null / 不在 children 里 ⇒ 退回"追加到末尾"（新加的块本来就该在后面）。
## 返回新元素。
func replace_child_element(old: UIBase, name_: String, ui_class: String, cfg: Dictionary = {}) -> UIBase:
	var arr_index: int = children.find(old) if old != null else -1
	var keep: bool = old != null and old.control != null and old.control.get_parent() != null
	var box_index: int = old.control.get_index() if keep else -1
	remove_child_element(old)
	var child: UIBase = add_child_element(name_, ui_class, cfg)
	if child == null:
		return null
	if arr_index >= 0:
		children.erase(child)
		children.insert(arr_index, child)
	if keep and child.control != null:
		var box: Control = child.control.get_parent() as Control
		if box != null and box_index < box.get_child_count():
			box.move_child(child.control, box_index)
	return child


## 递归摘掉一棵子树（clear_children / remove_child_element 的实现，别在别处再写一份）。
## 控件**立刻**从树上摘下来再 queue_free：只 queue_free 的话本帧它还挂在树上——
## 位置还占着、还会被画一次（重铺一段就会看着"重复了一份"，原地换的位置计算也会差一位）。
static func _remove_subtree(ui: UIBase) -> void:
	if ui == null:
		return
	for child in ui.children.duplicate():
		_remove_subtree(child)
	ui.children.clear()
	RegSys.unregister(ui)
	if ui.control != null:
		var box: Node = ui.control.get_parent()
		if box != null:
			box.remove_child(ui.control)
		ui.control.queue_free()
		ui.control = null


## 取一个在本元素下**唯一**的子元素名：本元素这边只负责"哪些名字已经被兄弟占了"，
## 去重规则本身在 `RegSys.unique`（名字的事只有那一处；角色走 `RegSys.register` 的 dedup，同一条后缀规则）。
## 为什么按"同一挂载点下不重名"判：登记名 = `挂载点登记名/名字`（见 RegSys.join），
## 同一挂载点下同名 = 同一个登记名 = 互相覆盖（后建的把先建的挤掉，指针也只命中一个）。
## 判重看的是**本元素已有的子元素**（配置里的与运行时加的都算），不查登记表：
## 建树时父元素自己还没登记，查表反而不准。
## **不给 `from`**（永远从"基名"试起）⇒ 按当下兄弟名判、**可回收**：`replace_child_element`
## 那种"摘掉旧的、用同一个名字再造一个"才保得住名字（见 RegSys.unique 的说明）。
## 被谁用：_build_children、add_child_element。
func _unique_child_name(want: String) -> String:
	var taken: Array[String] = []
	for child in children:
		taken.append(child.name)
	return RegSys.unique(want, func(n: String) -> bool: return taken.has(n))


## 子元素挂载点（默认直接挂 control；容器类覆写返回内部布局节点）。
## 被谁用：_build_children、add_child_element。
func _content_box() -> Control:
	return control


## 本元素自己的"叠加层"（非容器、画在内容之外、不被滚动裁）：面板（`UI_Panel`）有一份，其余元素没有。
## 默认 null；覆写者：UI_Panel。
## 被谁用：_free_box（往上找最近的一个）。
func _own_free_layer() -> Control:
	return null


## 本元素是不是在"**以面板为准**"的环境里（自己或任一祖先面板写了 `fit_content: false`）？
## 那种面板的尺寸是**定死的**（见 UI_Panel），里面内容得**照给到的宽折行**，不能反过来把面板撑开：
##   · `UI_Label` 据此改成"宽度听容器"（不按内容报宽，见它的 `_content_size`）。
## 默认情况（不写那个键）= 内容为准，一路为 false，行为与以前完全一样。
## **自由定位的元素（浮窗 / 菜单 / 角落图标）自成一体**：走到它就停下，以它自己的声明为准——
## 不再往它挂着的那个宿主面板看。否则"面板一进以面板为准，浮窗里的文字也去听容器"，
## 而浮窗自己又是内容为准 ⇒ 文字报 0 宽、拿到 1px ⇒ **折成一列**（实测：关闭/缩放按钮的说明浮窗
## 变成 17×112 的一条）。浮窗要固定尺寸就自己写 `fit_content: false`，那一路照常生效。
## 被谁用：UI_Label._content_size。
func _in_fixed_panel() -> bool:
	var ui: UIBase = self
	while ui != null:
		if ui.config.get("fit_content", true) == false:
			return true
		if bool(ui.config.get("free", false)):
			break                  # 自由定位的元素自成一体（见上）：不再往它挂着的宿主面板看
		ui = ui.parent
	return false


## 自由定位子元素（`free: true`，如浮窗 / 子菜单 / 关闭按钮）的挂载点：**从本元素往上找最近一个有
## 叠加层的祖先**，都没有才退回自己的内容盒。
## 为什么不直接挂自己的 control：**叶子元素（文本 / 菜单项）与滚动容器都会把"画到自己矩形外"的子元素
## 裁掉**——文本的内核 RichTextLabel 自带 `clip_contents`，滚动容器也要裁（不然滚动露馅）；
## 而浮窗、子菜单正是要画到外面去（实测：浮窗只剩约一条边，看着就是"开不出来"）。
## **元素层的父子关系不变**：`child.parent` 仍是本元素（登记名、失焦判定的挂载点、`@self.parent` 链
## 全都照旧），变的只是 Control 挂在谁下面 ⇒ `show_at` 按"实际父控件"换算坐标，位置照样准。
## 被谁用：_build_children、add_child_element（两条加子元素的路的 free 分支）。
## 覆写者：UI_Panel（它自己就有叠加层，直接返回，不必爬）。
func _free_box() -> Control:
	var ui: UIBase = self
	while ui != null:
		var layer: Control = ui._own_free_layer()
		if layer != null:
			return layer
		ui = ui.parent
	return _content_box()


## 自由定位子元素"贴角"时使用的**角落容器**：同一个角上放多个（关闭 / 缩放 / 改尺寸…）时，
## 它们在里面自动排成一行——**角上那个永远是最先加的那个，新加的排在离角远的一端**。
## 默认 null = 没有角落容器，自己按锚点钉（见 `_anchor_free_child`，只有一个图标时够了）。
## 覆写者：UI_Panel（四角各一个 HBox，按需建）。
## 被谁用：_attach_child_control。
func _corner_box(_at: int) -> Control:
	return null


## 把子元素的控件**挂到该去的地方**，并做收尾定位——挂载规则只有这一份
## （普通子 → 内容盒；free 子 → 叠加层，贴角的进角落容器）。
## 被谁用：_build_children（配置里的子元素）、add_child_element（运行时追加）。
func _attach_child_control(child: UIBase, child_config: Dictionary) -> void:
	var loose: bool = bool(child_config.get("free", false))
	var corner: Control = _corner_box(int(child_config.get("open_at", Enums.OpenAt.CONFIG))) if loose else null
	var box: Control = corner if corner != null else (_free_box() if loose else _content_box())
	box.add_child(child.control)
	if corner == null:
		_anchor_free_child(child)
		return
	# 角落容器里"新加的排在离角远的那一端"（右角的往左排）：
	# 于是**先加的那个一直贴在角上**（关闭按钮就是最先加的那个），后加的依次往外排。
	var row: BoxContainer = corner as BoxContainer
	if row != null and row.alignment == BoxContainer.ALIGNMENT_END:
		row.move_child(child.control, 0)


## 自由定位子元素可以"**贴父级某个角**"（config["open_at"] 写 `ANCHOR_*_IN` 那两个，
## 如右上角的关闭按钮、右下角的缩放按钮）：用**控件锚点**钉上去，而不是算一次坐标——
## 父级常是"宽高随内容"的（一览收 / 展一次尺寸就变），只算一次就飞了；
## 锚点由引擎维护，父级尺寸一变位置自己跟上，不用我们去连信号追。
## **只认"内部右上 / 内部右下"**：其余 open_at 策略是"开在屏幕某处"，那是 open 的事（见 UISys._place）。
## 被谁用：_build_children / add_child_element（两条加子元素的路都要过这一道）。
static func _anchor_free_child(ui: UIBase) -> void:
	if not bool(ui.config.get("free", false)):
		return
	var c: Control = ui.control
	var at: int = int(ui.config.get("open_at", Enums.OpenAt.CONFIG))
	var top_right: bool = at == Enums.OpenAt.ANCHOR_TOP_RIGHT_IN
	var bottom_right: bool = at == Enums.OpenAt.ANCHOR_BOTTOM_RIGHT_IN
	if c == null or not (top_right or bottom_right):
		return
	var w: float = c.size.x if c.size.x > 0.0 else c.custom_minimum_size.x
	var h: float = c.size.y if c.size.y > 0.0 else c.custom_minimum_size.y
	c.anchor_left = 1.0                     # 右边缘：钉在父级右边
	c.anchor_right = 1.0
	c.anchor_top = 0.0                      # 上边缘：钉在父级上边（右下那个用负偏移往下挂）
	c.anchor_bottom = 0.0
	c.offset_left = -w
	c.offset_right = 0.0
	c.offset_top = 0.0 if top_right else -h
	c.offset_bottom = h if top_right else 0.0


## 应用 config 里的公共属性：position / size / content / visible / font_size / font_color / background。
## 被谁用：build()。子类覆写时必须先 super()（先让基类定好控件尺寸，再按自己的控件补一道）。
func _apply_config() -> void:
	refresh("position")
	reapply()


## 重新应用"**只有应用时才生效**"的那几项公共属性：size / font_size / font_color / background。
## 与 _apply_config 的差别：**不碰 position**——位置会被拖动这类运行期行为偏离，
## 改别的键时不该顺手把窗口拽回配置里那个位置（见 UIBase.refresh 关于 position 的说明）。
## 被谁用：_apply_config（build 时整份应用）、UI_Editor（编辑器改完 config 让界面跟上，见它改完那几步）。
func reapply() -> void:
	if control == null:
		return          # 已被移除的动态 UI：控件没了，没什么可应用
	# "配置想要多大"走 `_config_size()`（`size` 与 `size_ratio` 两种写法都在它里面，别在这儿另读一遍）：
	# 两维都给了才在这里先套上——写 0 的那一维随内容走，由 _fit_size 补（那是它的活）。
	var want: Vector2 = _config_size()
	if want.x > 0.0 and want.y > 0.0:
		control.custom_minimum_size = want
		control.size = want
	# visible / position 不在这里设：它们由 refresh() 统一"让界面跟 config 一致"
	# （build 里紧跟着就会调 refresh()，位置用 refresh("position")；content 由子类 refresh 读）
	# 字号/字色是通用属性（谁都能配），作用在**本元素的控件**上：
	# 主题重写只在配它的那个控件上生效，**不会自动传给子控件**——要小字号/深色字请配到真正显示文本的那个元素上。
	# （不配字色就用主题默认：Godot 默认主题是接近白色的，画在浅色底图上会看不见。）
	# **字号有下限**：没配就用默认字号，配了比它小也抬到默认（见 SysCfg.ui_font_size_default）——
	# "小到看不清"的界面没法用；要更小就改那个全局值（在这里各写各的没用）。
	var font_size: int = maxi(int(config.get("font_size", SysCfg.ui_font_size_default)),
		SysCfg.ui_font_size_default)
	control.add_theme_font_size_override("font_size", font_size)
	# **字体也在这一处**（全局默认字体，见 UISystem.apply_default_font）：
	# 走**控件级覆盖**——主题链上引擎默认主题对每种类型都自带字体，只有控件自己的覆盖一定盖得住
	# （实测：只设根窗口主题的 default_font，TextEdit 拿到的还是 Open Sans）。
	# 字号与字体是一个入口：想换字体改 `SysCfg.ui_font_file`，别在各个配置里各写各的。
	if UISys.ui_font != null:
		control.add_theme_font_override("font", UISys.ui_font)
	# **字色也是这一处**：没配 `font_color` 就用全局默认（`SysCfg.ui_font_color_default`，深色）——
	# 面板底是浅色图（见 SysCfg.ui_background），引擎默认那接近白的字画在白底上等于看不见。
	# 要深底浅字：改那个全局值，或给这一处显式配 `font_color`。
	control.add_theme_color_override("font_color",
		config.get("font_color", SysCfg.ui_font_color_default))
	_apply_background(str(config.get("background", "")))


## 虚接口 + 通用实现：给本元素铺一张背景图（config["background"] = 纹理路径）。
## 做法 = 给它**主题里那个"当底"的 stylebox 槽**套上九宫格图（槽名见 _background_slot）：
##   UI_Panel→panel（内层 PanelContainer）、UI_Label→normal……
## 控件一个槽都没有（TextureRect / 纯 Control，本身不画 StyleBox）就画不出来：警告一次、不画。
## 那种元素要"带底"请换有槽的元素（文字带底 = UI_Panel 里放 UI_Label，键盘的键就是这么做的）。
## 被谁用：_apply_config。覆写者：UI_Panel（它要套在内层 _panel 上，不是根 Control）。
func _apply_background(path: String) -> void:
	var style: StyleBoxTexture = _make_background(path)
	if style == null:
		return
	var slot: String = _background_slot()
	if slot == "":
		push_warning("UIBase「%s」(%s): 控件没有可用的 stylebox 槽，画不出背景 %s"
			% [name, control.get_class() if control != null else "?", path])
		return
	control.add_theme_stylebox_override(slot, style)


## 本元素用哪个 stylebox 槽当底：按 SysCfg.ui_background_slots 取第一个存在的；一个都没有 → 空串。
## 被谁用：_apply_background。（UI_Panel 不走这里：它把图套在内层 PanelContainer 的 "panel" 上）
func _background_slot() -> String:
	if control == null:
		return ""
	for slot in SysCfg.ui_background_slots:
		if control.has_theme_stylebox(slot):
			return slot
	return ""


## 造一张九宫格背景样式（供 config["background"] 用）；路径为空/图片不存在/加载失败返回 null。
## 九宫格的边距取 config["background_slice"]（**每张图各自指定**，不写 = 全局默认
## `SysCfg.ui_background_slice`：默认那张就是按它量的；要"整张拉伸"显式写 0）：
## 每张图的圆角半径不一样（Unity 那边每张 sprite 也自带自己的九宫格参数），所以要能逐个指定。
## 被谁用：_apply_background（本类与 UI_Panel 的覆写）。
func _make_background(path: String) -> StyleBoxTexture:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		push_warning("UIBase「%s」: 背景图不存在，改用默认样式：%s" % [name, path])
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = tex
	style.set_texture_margin_all(int(config.get("background_slice", SysCfg.ui_background_slice)))  # 圆角不被拉伸
	return style


## 组装子元素：config["children"] 每项 [child_name, ui_class, child_config]。
## 子元素的挂载对象（parent）即本元素（父 UI），其指令里的 `@self.parent` 指向本元素。
## 挂载点与运行时那条路**同一套规则**（见 add_child_element）：配了 free 的挂到叠加层
## （绝对定位，position/size 不被父级布局改），没配的进内容盒（容器类 = 竖排）。
## 被谁用：build()。（运行时加子元素走 add_child_element，那条路要额外登记。）
func _build_children() -> void:
	for item_raw in config.get("children", []):
		if not (item_raw is Array):
			continue
		var item: Array = item_raw
		if item.size() < 2:
			continue
		var child_config: Dictionary = item[2] if item.size() > 2 else {}
		var child: UIBase = UIPreset.create_element(item[0], item[1], child_config)
		if child == null:
			continue
		child.parent = self
		child.name = _unique_child_name(child.name)     # 重名自动加后缀（同一挂载点下不重名）
		child.build()
		children.append(child)
		# free 的挂到叠加层（非容器，位置/尺寸保持配置值），贴角的进"角落容器"自动排队；
		# 其余进内容盒（竖排布局）。挂到哪、怎么定位只有一份实现（见 _attach_child_control）。
		_attach_child_control(child, child_config)


## 唯一事件入口（PointerDetect 派发）：参数是事件名——状态驱动的事件就是配置里的状态名
## （如 "Pointer 1 Hold"、"Right | Tick"；UI 不感知按键，键位只在状态层出现），
## hover 变化用 QName.pointer_enter / QName.pointer_exit。
## 事件→指令：在 config["events"]（`[事件名, 指令串]` 列表）里取出**所有**同名项，**逐条发送**。
## **同一个事件可以绑多条**（按配置顺序都执行）——"按住既要能拖、又要按点了哪段链接做事"就是两条：
##   [QName.pointer1_hold, 'UIInteract.drag(@host, @event)'],      ← 按住就拖
##   [QName.pointer1_hold, 'UIInteract.meta_event(@self)'],       ← 再看"指针下那段链接"，跑它自己的指令
## 一条都没匹配上才**冒泡给父级**：于是"整块面板的行为"在它的子元素上同样生效
## （如菜单面板启用拖拽后，按住菜单项也能拖；`@self` 与它上面的取值链都以配了指令的那个元素为基准）。
## 冒泡到根仍没有配置就什么都不做（元素没有隐式行为）。
## 用列表而不是字典键：与 config 里的属性分开（属性名与事件名不会互相撞车），
## 且要加新事件只需往列表里加一项。
## 指令串里的 `@self` / `@host` / `@event` **由指令系统解析**（见 CommandParser 的 event_ui / event_name：
## 本类只负责派发前把"当前元素 + 事件名"告诉它），所以这里不再扫字符串、也没有占位符替换那一套。
## 被谁用：PointerDetect.key（状态事件）、PointerDetect._process（enter/exit）、本函数自身（冒泡）。
func on_event(event_name: Variant) -> void:
	var hit: bool = false
	for entry in config.get("events", []):
		if not (entry is Array):
			push_warning("UIBase「%s」: config[\"events\"] 的项应为 [事件名, 指令串]，收到 %s" % [name, type_string(typeof(entry))])
			continue
		var pair: Array = entry
		if pair.size() < 2 or pair[0] != event_name:
			continue
		hit = true
		# 派发前把"当前元素 + 事件名"告诉指令系统（`@self` / `@host` / `@event` 认它们），
		# 发完**还原**：嵌套派发（事件里又开 UI 又触发事件）时才不会被里层盖掉，
		# 也不会留下"上一次的 @self"让事件之外发的指令指错东西。
		var prev_ui: Object = CommandParser.event_ui
		var prev_name: String = CommandParser.event_name
		CommandParser.event_ui = self
		CommandParser.event_name = str(event_name)
		Msg.send_cmd(pair[1])
		CommandParser.event_ui = prev_ui
		CommandParser.event_name = prev_name
	if hit:
		return                      # 命中过（哪怕只一条）就不再往上冒泡：这一层认领了这个事件
	if parent != null:
		parent.on_event(event_name)


## 本条 UI 链的**管理对象**（宿主）——"最近声明优先，没声明回退顶层"：
##   从自己往上找**最近一个在 config 里写了 `host` 的元素**（值是**注册名**，见 RegSys）⇒ 它就是
##   这段子树的管理对象；谁都没写 ⇒ 回退到**最外层 UI**（挂 UI 根的"窗口"本身，以往的行为）。
## 于是"一个管理菜单，不论它的子 UI 层级在哪，管的都是同一个对象"——指令里不必数级数。
## 独立 UI（没挂在谁下面、也没声明）的宿主就是它自己。
## **为什么存名字**：config 是数据（会深拷贝、可能写盘），实例存不进去；注册名是字符串，
## 可读、能存盘、跨运行也对得上。**是"管理对象"不是"挂载点"**：挂哪、摆哪仍由 open 决定。
## 取不到（名字没登记 / 那个 UI 已经不在了）⇒ 当"没声明"处理并提醒一次（见 _warn_host_once）。
## 被谁用：CommandParser._instance_of（`@host`）。
func _find_host() -> UIBase:
	var fallback: UIBase = self
	var ui: UIBase = self
	while ui != null:
		var found: UIBase = _host_of(ui.config.get("host"))
		if found != null:
			return found
		fallback = ui          # 一直没声明（或声明用不了）⇒ 循环结束时它是最外层那个
		ui = ui.parent
	return fallback


## 解析一处 `config["host"]` 声明，返回它指的那个 UI；没声明 / 用不了给 null。
## **写的就是注册名**（如 `"UI/MiniHUD/Menu"`，见 RegSys）——ID 是运行期的东西（每次运行都变），
## 配置里不再出现它（要指哪个 UI 就写名字，读起来也认得）。
## 用不了（名字没登记 / 那个 UI 已经不在了）⇒ null 并经 _warn_host_once 提醒一次。
## 被谁用：_find_host。
static func _host_of(declared: Variant) -> UIBase:
	if declared == null:
		return null
	var ui: UIBase = RegSys.get_(str(declared)) as UIBase
	if ui == null:
		_warn_host_once(str(declared))
	return ui


## 已经警告过的 host 值（按值去重，一局只提示一次；见 _warn_host_once）。
static var _warned_hosts: Dictionary = {}


## host 值用不了时**提醒一次**（按值去重，一局只提示一次，不刷屏——这个解析每次派发都会跑）。
## 提醒后按"当没声明"处理（继续往上 / 回退顶层）。被谁用：_find_host。
static func _warn_host_once(raw: String) -> void:
	if _warned_hosts.has(raw):
		return
	_warned_hosts[raw] = true
	push_warning("UIBase: config[\"host\"] = %s 用不了（这里写**注册名**，如 `MiniHUD/Menu`。也可能是那个 UI 已经不在了）—— 当没声明处理" % raw)


## 说明：以前这里有一整套"把 `self` / `host` / `event` 三个词扫出来换成 `@注册名`"的助手
## （`_resolve_cmd` / `_word_to` / `_is_word_char` …）。现在指令系统自己认 `@self` / `@host` / `@event`
## （见 CommandParser._instance_of 与 event_ui / event_name），所以那一整套删掉了——
## 配置里直接写 `@self.parent` / `@host.config.content_cmd` / `UIInteract.drag(@host, @event)` 即可。


## 运行时追加一个子元素（如菜单里后加的关闭按钮），返回新元素。
## 生成控件 → 挂到 _content_box()/_free_box() → 记进 children → 交给 UISys 登记
## （登记后才可能被指针命中；登记名规则在 UISys）。
## 登记名走 UISys 唯一那条规则（`挂载点登记名/名字`），所以"开出来的 UI"与"配置里的子元素"命名一致。
## 被谁用：UIInteract_OpenClose._build_open（挂到宿主/锚点下的 UI）、UIInteract_OpenClose.close 的取件路径（_child_ui）。
func add_child_element(child_name: String, ui_class: String, child_config: Dictionary = {}) -> UIBase:
	var child: UIBase = UIPreset.create_element(child_name, ui_class, child_config)
	if child == null:
		return null
	child.parent = self
	child.name = _unique_child_name(child.name)             # 重名自动加后缀（同一挂载点下不重名）
	child.build()
	children.append(child)
	# 配置里声明 free 的当"自由定位"元素：挂到叠加层，位置才不会被父级容器布局覆盖。
	# 注意不要给它设 Control.top_level——那样它就不再继承父级可见性，宿主关了它还会留在屏幕上；
	# 摆放时把屏幕坐标换算成挂载点坐标系的 position 即可（见 UISys._place）。
	_attach_child_control(child, child_config)
	UISys.register_child(self, child)
	return child
