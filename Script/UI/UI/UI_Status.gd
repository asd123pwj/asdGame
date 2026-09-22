class_name UI_Status
extends UI_Panel
## **角色状态一览（只读 + 实时）**：把一个角色**装着的状态**逐个摆出来——每个状态一段，
## 段里是"它依赖什么（声明）+ 现在触发成什么样 + 满足没有 + 最近一次收到的消息"。
##
## **为什么需要一个专门元素**（这正是状态系统的特殊之处）：
##   · 状态是**静态预设**——一个状态全项目就一份（`StatusPreset._we`，见 Character/Status/Status.md），
##     它身上既有"声明"（`_x_listeners`），又有**所有角色混在一起**的现状（`_x_triggers`、satisfied…）；
##   · 而"这个角色现在怎样"是**按角色**分开存的：`_attr_triggers[角色]`、`satisfied[角色]`…
##   ⇒ 所以要看到"某个角色的状态"，必须把两半拼起来：**声明从预设读，现状一律按名字取那个角色的那一份**
##      （`preset._attr_triggers[char_]` 这种）。只读预设会把所有角色混在一起，只读 `Statuses` 又看不到依赖与触发真值。
##
## **看哪个角色**（按顺序找）：
##   1. UI 通用的**查看项** `content_cmd`（自己的，或外壳上写的）——于是任何一次 open 都能指定：
##      `UIInteract.open(preset_name="Status", content_cmd="@Char/人类")`；
##   2. 本元素 config 的 `char`（预设里写的默认，指令路径/引用如 `"@Char/SYS"`，**要带 `@`**）；
##   3. 都取不到 ⇒ 铺一行红字说清该写什么（不猜、不默认到某个角色）。
## `content_cmd` 优先（它是"**这一次**想看谁"，`char` 是"没指定时看谁"）；取角色就是
## `CommandParser.read(路径)`（只读，不改任何东西）。
##
## **实时**：订阅被看角色**每个状态**的 `satisfied` / `unsatisfied`（`Msg.listen_status_satisfied/unsatisfied`），
## 收到就**只重铺那一段**（其它段不动、收起还是收起）⇒ 标题上的 ✔/✘ 与段里的行当场跟着变。
##
## **监听的生命周期 = "开着就一直听，关掉就全退"**（照 `AutoSys.run_until_unsatisfied` 那种
## "不需要了就自己删登记"的思路）：
##   · **不看段展开没展开**——收起的段，标题上也写着 ✔/✘，它照样得是实时值，所以**开着就把所有状态全订上**；
##   · 面板被关掉（`UIInteract.close`）⇒ 全退订，不留订阅挂在消息系统里；
##   · **重开**（复用同一份 UI）由 `UIBase.on_shown` 那一声自动重新订上（open 不区分"新建 / 复用"，两条路都会通知）。
## 于是"开着的时候精确、关掉之后干净"。
##
## 一个状态 = **一段可折叠分组**（默认收起）：标题给"满足 ✔/✘ + 依赖条数"一眼看全局；
## 展开才建每条依赖的行（`items` 按需建，见 UIInteract_Fold）——状态多的时候打开也不卡。

## 六组"声明 ↔ 当前触发"的配对：显示名 + StatusPreset 里那两个成员名（顺序与它的文件头一致）。
## 用成员名去取（`preset.get(...)`）而不是写死六遍代码：加一组监听也只改这张表。
const GROUPS: Array[Array] = [
	["属性", "_attr_listeners", "_attr_triggers"],
	["加成", "_buff_listeners", "_buff_triggers"],
	["状态", "_status_listeners", "_status_triggers"],
	["交互", "_interaction_listeners", "_interaction_triggers"],
	["按键", "_key_listeners", "_key_triggers"],
	["时间", "_time_listeners", "_time_triggers"],
]

## 铺过没有（只铺一次；重铺走 reload）。
var _built: bool = false
## 上次铺的时候看的是哪个角色：知道"换了对象"就能自动重铺（见 refresh）。
var _path_shown: String = ""
## 每个状态那一段：状态名 -> 段（UI_Panel）。收到状态变化时就地重铺其中一段。
var _secs: Dictionary = {}
## 当前订阅的"状态满足 / 解除"：`[[消息 ID, 回调], ...]`（退订两样都要，见 MsgBus.unlisten）。
var _subs: Array[Array] = []
## 面板现在是不是"被显示着"（由 on_shown / on_hidden 维护，见 UIBase）。
## **为什么要这个标记**：判断"该不该听"不能只看控件可见性——整块收起时子元素是隐藏的（可见性为 false），
## 但面板本身还开着；而且 `_fill` 是**延迟一帧**跑的，可能晚于"被关掉"那一声 ⇒ 只看可见性会误订。
var _shown: bool = false


## 登记完成 ⇒ 铺内容（铺出来的子元素要登记，而登记要拿父级名字，所以得等自己有名字，见 UIBase.on_registered）。
## **推迟一帧**：`open` 那次临时配置（`content_cmd=…`）是建完之后才 merge 上的，
## 登记这一刻还读不到，等一帧就齐了（同 UI_Editor）。
func on_registered() -> void:
	if _built:
		return
	_built = true
	Callable(self, "reload").call_deferred()


## 被显示 ⇒ 订上所有状态消息（open 新建 / 复用两条路都会走到这儿，见 UIBase.on_shown）。
func on_shown() -> void:
	_shown = true
	sync_listening()


## 被关掉 ⇒ 全退订：都看不见了，没必要挂在消息系统里（见 UIBase.on_hidden）。
func on_hidden() -> void:
	_shown = false
	_unlisten_all()


## 重铺（"[刷新]"那一行、以及"换了看的角色"时调它）：把铺出来的整棵子树丢掉再铺一遍。
## 为什么整棵丢掉：触发真值、状态集合都可能变了，"就地改行"要写一堆映射，不如重铺干净。
## 先 clear 再铺 ⇒ 重复调用不会铺出两份（延迟调用可能比"再来一次刷新"晚到）。
func reload() -> void:
	if control == null:
		return                       # 已经被关了 / 被移除了（延迟调用可能晚到）
	clear_children()
	_secs.clear()
	_path_shown = _char_path()
	_fill()


## 刷新：**看的角色换了就重铺**（谁把刷新传到本元素上就自愈；`_built` 之前只当普通刷新）。
## 会走到这儿的路径：`UISys.refresh_all` 那种"挨个刷一遍"、以后谁在外壳上往下刷。
## 注意**换人最直接的用法是点 `[刷新]`**（那行直接调 reload）：`open` 复用同一份 UI 时
## 只 refresh 外壳，不会自动传到 Body 元素上（要传得靠上面那两条路）。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if _built and control != null and _char_path() != _path_shown:
		reload()


## 铺：抬头（看谁 + [刷新]）→ 取不到角色就说清怎么给 → 逐个状态一段 → 订上所有状态消息。
func _fill() -> void:
	if control == null:
		return                       # 这一帧里已经被关了 / 被移除了（延迟调用可能晚到）
	_unlisten_all()                  # 重铺 = 先全退，末尾按"开着没开"再订（见 sync_listening）
	add_child_element("Where", "UI_Label", {
		"content": "角色状态：%s" % _char_path(),
		"font_color": Color(0.62, 0.68, 0.78),
	})
	add_child_element("Reload", "UI_Label", {
		"content": "[刷新]（重读 + 重订）",
		"events": [[QName.mouseLeft, "@self.parent.reload()"]],
	})
	var char_: Character = _character()
	if char_ == null:
		add_child_element("None", "UI_Label", {
			"content": "找不到角色「%s」——写 char=\"@Char/SYS\" 这种注册名（指令路径）" % _char_path(),
			"font_color": Color(0.85, 0.55, 0.55),
		})
		return
	if char_.statuses == null:
		add_child_element("NoSet", "UI_Label", {"content": "这个角色还没有状态集合"})
		return
	var dict: Dictionary = char_.statuses.statuses
	var names_: Array = dict.keys()
	names_.sort()
	add_child_element("Count", "UI_Label", {
		"content": "共 %d 个状态（点标题展开看依赖与触发；标题上的 ✔/✘ 是实时的）" % names_.size(),
		"font_color": Color(0.55, 0.60, 0.70),
	})
	for status_name in names_:
		_section(char_, dict[status_name])
	sync_listening()


## ---------- 实时：订阅 / 退订（开着就全订，关掉就全退）----------
## 按"现在该不该听"重算订阅（**幂等**，随便调）：
##   · 面板没被显示（关掉了）/ 没角色 ⇒ 全退订；
##   · 否则**把被看角色的所有状态都订上**——收起的段标题也写着 ✔/✘，照样要实时值
##     （整块收起时也不退：那只是"暂时没看"，一展开就该是新的）。
## 判断"开着没开"看 `_shown`（on_shown / on_hidden 维护），**不看控件可见性**：整块收起时子元素是隐藏的，
## 而"隐藏"与"被关掉"是两回事。
## 被谁用：on_shown、on_hidden、_fill 末尾、以及需要重算的地方。
func sync_listening() -> void:
	var char_: Character = _character()
	if not _shown or char_ == null or char_.statuses == null:
		_unlisten_all()
		return
	_unlisten_all()                  # 先全退再订：订的东西很少，简单可靠（不玩增量）
	for status_name in char_.statuses.statuses.keys():
		_subscribe(char_, str(status_name))


## 订阅一个状态的"满足 / 解除"两条消息（回调里就地重铺那一段）。
## 用 lambda 而**不用 `Callable.bind`**：Callable 的 == 不比较绑定参数，退订时摘不掉
## （同 AutoSys._index_of 踩的那个坑）；lambda 不带绑定参数 ⇒ 同一个实例传回去就能摘掉（_subs 里存的正是它）。
func _subscribe(char_: Character, status_name: String) -> void:
	var on_hit: Callable = func(_msg): _on_status_changed(status_name)
	_subs.append([Msg.listen_status_satisfied(char_, status_name, on_hit), on_hit])
	var on_lost: Callable = func(_msg): _on_status_changed(status_name)
	_subs.append([Msg.listen_status_unsatisfied(char_, status_name, on_lost), on_lost])


## 退掉所有订阅（幂等；空表也安全）。
func _unlisten_all() -> void:
	for sub: Array in _subs:
		MsgBus.unlisten(sub[0], sub[1])
	_subs.clear()


## 某状态满足 / 解除了 ⇒ **只重铺这一段**（其它段不动），并保持它原来展开没展开。
## 为什么整段重铺：一次变化往往连"触发行、最近消息、满足情况"一起变，就地改每一行要写一堆映射；
## 段里的行只在展开时才有（很少），重铺一段很便宜。
func _on_status_changed(status_name: String) -> void:
	var sec: UIBase = _secs.get(status_name)
	_rebuild_section(status_name, sec != null and not bool(sec.config.get("collapsed", true)))


## 重铺一段：老段（连同它的行）摘掉，按现在的数据**在原地**再造一段；`open_` = 保持它原来展开着。
## 被谁用：_on_status_changed。
func _rebuild_section(status_name: String, open_: bool) -> void:
	var char_: Character = _character()
	if char_ == null or char_.statuses == null:
		return
	var preset: StatusPreset = char_.statuses.statuses.get(status_name)
	if preset == null:
		return
	_section(char_, preset, open_, _secs.get(status_name))


## 一个状态 = 一段：标题（满足情况 + 依赖条数）常显，内容（每一行）写成 `items` ⇒ **展开才建**。
## 默认收起（`collapsed: true`）：`title_item` 的箭头与它对上；展开时折叠交互会把 `items` 建出来。
## `open_ = true`（重铺一段时它原来展开着）⇒ 建完立刻 fold 一下，把 `items` 建出来，等价于"用户点开过"。
## `old` 给了 ⇒ **原地换掉它**（位置不变，见 UIBase.replace_child_element）：状态一变就重铺这一段，
## 直接"摘掉再加"会把这一段排到最底下（用户看着的次序不能自己动）。
func _section(char_: Character, preset: StatusPreset, open_: bool = false, old: UIBase = null) -> void:
	var sec_name: String = "S_" + preset.name
	var cfg: Dictionary = {
		"size": [0, 0],
		"collapsed": not open_,
		"items": _rows(char_, preset),
		"children": [UIInteract_Fold.title_item(_section_title(preset, char_), not open_)],
	}
	var sec: UIBase = replace_child_element(old, sec_name, "UI_Panel", cfg) if old != null \
		else add_child_element(sec_name, "UI_Panel", cfg)
	_secs[preset.name] = sec
	if open_:
		UIInteract_Fold.fold(sec, false)


## 段标题：状态名 + 满足情况 + 依赖条数（一眼看全局的那行；**这一行是实时的**，收到状态消息就重铺这一段）。
static func _section_title(preset: StatusPreset, char_: Character) -> String:
	return "%s（%s｜依赖 %d 条）" % [preset.name,
		"✔ 满足" if _satisfied(preset, char_) else "✘ 未满足", _dep_count(preset)]


## 一段里的所有行（`[名字, 元素类, 配置]` 三元组，格式同 `children`）。
## 行分三种：现状（满足 / 最近消息 / 三个开关）、每组依赖的组名、每条依赖"声明 → 触发真值"。
## 触发为真标绿、为假标灰——一眼看出"是哪一条没满足"。
func _rows(char_: Character, preset: StatusPreset) -> Array:
	var sat: bool = _satisfied(preset, char_)
	var out: Array = [
		_row("Now", "满足：%s" % ("✔" if sat else "✘"),
			Color(0.55, 0.80, 0.55) if sat else Color(0.75, 0.55, 0.55)),
		_row("Msg", "最近消息：%s" % _brief(preset.latest_message.get(char_))),
		_row("Decl", "auto_reset=%s   match_any=%s   with_detect=%s"
			% [preset.auto_reset, preset.match_any, preset.with_detect]),
	]
	var total: int = 0
	for group in GROUPS:
		var listeners: Array = preset.get(str(group[1]))
		if listeners.is_empty():
			continue
		out.append(_row("G_%s" % str(group[0]),
			"【%s 依赖：%d 条】" % [str(group[0]), listeners.size()],
			Color(0.62, 0.68, 0.78)))
		# **按角色取触发真值**：预设里那张表是"所有角色混在一起"的，这里只拿这个角色那一份
		var triggers: Dictionary = preset.get(str(group[2])).get(char_, {})
		var i: int = 0
		for lt: ListenType in listeners:
			var hit: bool = bool(triggers.get(lt.name, false))
			out.append(_row("L_%s_%d" % [str(group[0]), i], "%s   → %s"
				% [_dep_text(lt), "✔ 已触发" if hit else "✘ 未触发"],
				Color(0.55, 0.80, 0.55) if hit else Color(0.75, 0.55, 0.55)))
			total += 1
			i += 1
	if preset.with_detect:
		var hit: bool = bool(preset._detect_triggers.get(char_, false))
		out.append(_row("G_detect", "【外部检测】→ %s" % ("✔ 已触发" if hit else "✘ 未触发"),
			Color(0.55, 0.80, 0.55) if hit else Color(0.75, 0.55, 0.55)))
		total += 1
	if total == 0:
		out.append(_row("NoDep", "（没有依赖声明——靠外部检测，或恒不满足）",
			Color(0.45, 0.48, 0.55)))
	return out


## 该状态当前是否满足（**按角色**查：`satisfied[char_]`，没记过当 false）。
static func _satisfied(preset: StatusPreset, char_: Character) -> bool:
	return bool(preset.satisfied.get(char_, false))


## 依赖条数（六组监听器 + 外部检测），只用于标题那行摘要。
static func _dep_count(preset: StatusPreset) -> int:
	var n: int = 1 if preset.with_detect else 0
	for group in GROUPS:
		n += (preset.get(str(group[1])) as Array).size()
	return n


## 一条依赖的显示文本：`名字  条件 [阈值]`（如 `Health  > 50`、`Tick  Advance`、`Mouse Left  HOLD`）。
## 阈值没给（INT64_MIN 是 ListenType 的"未给"哨兵）就不显示，别印一串没意义的数字。
static func _dep_text(lt: ListenType) -> String:
	var out: String = "%s  %s" % [str(lt.name), _match_text(lt.match_type)]
	if lt.thres != INT64_MIN:
		out += " %d" % lt.thres
	return out.strip_edges()


## 比较条件的显示文本：按键那组的 match_type 是枚举值（HOLD / PRESS / RELEASE），转成名字好看；
## 其余（">" / "Present" / "Advance" / "AnyChanged"…）本来就是字符串，原样。
static func _match_text(match_type: Variant) -> String:
	var kinds: Dictionary = Enums.KeyStatus
	if match_type is int and kinds.has(match_type):
		return str(kinds.find_key(match_type))
	return str(match_type)


## 一行 `[名字, 元素类, 配置]`（行都是只读的 UI_Label，只换文字与颜色）。
## 不写 `font_size`：用全局默认字号（也是最小字号，见 SysCfg.ui_font_size_default）——写小了也会被抬上来。
static func _row(row_name: String, text: String, color: Color = Color(0.75, 0.78, 0.85)) -> Array:
	return [row_name, "UI_Label", {"content": text, "font_color": color}]


## 值的短文本：null 说"（无）"，太长截断（最近消息里可能挂着一整个角色/字典）。
static func _brief(value: Variant) -> String:
	if value == null:
		return "（无）"
	var text: String = str(value)
	return text if text.length() <= 48 else text.substr(0, 48) + "…"


## 看的是哪个角色（顺序 = "这一趟想看谁" 优先于 "没指定时看谁"）：
##   1. `content_cmd`：自己的，再**沿外壳往上**找（`open(..., content_cmd=…)` 写在外壳那层）；
##   2. 自己的 `char`（预设里写的默认）；
##   3. 都没有 ⇒ 空串（_fill 铺一行红字告诉用户写什么）。
## 不认 `content` 字面值：那多半是"这个 UI 显示的文字"，不是"角色在哪"（同 UI_Editor._target_path 的判断）。
func _char_path() -> String:
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
	return str(config.get("char", ""))


## 按路径取角色（读不到 / 不是角色都给 null，由 _fill 铺一行提示）。
func _character() -> Character:
	var path: String = _char_path()
	if path == "":
		return null
	var got: Array = CommandParser.read(path)
	return (got[1] as Character) if bool(got[0]) else null
