class_name UI_Status
extends UI_View
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
## **看哪个角色 / 铺 / 订的骨架都在 `UI_View`**（"查看项 `content_cmd` 优先，其次 config 的 `char`"、
## "推迟一帧铺"、"换对象自动重铺"、"开着才听 / 关掉全退 / 重开订回"）。本元素只管两件事：
##   · **铺什么**（`_fill`）：每个状态一段；
##   · **订什么**（`_listen`）：每个状态的 `satisfied` / `unsatisfied` + `trigger_changed` + 两种外部检测
##     （收起的段标题上也写着 ✔/✘ ⇒ **开着就把所有状态全订上**，不看段展开没展开）。
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

## 每个状态那一段：状态名 -> 段（UI_Panel）。收到状态变化时就地重铺其中一段。
var _secs: Dictionary = {}


## 清掉"状态 → 段"的索引（重铺时由 UI_View.reload 调）。
func _before_fill() -> void:
	_secs.clear()


## 铺：抬头 → 取不到角色就说清怎么给 → 一行总计 → 逐个状态一段。
func _fill() -> void:
	_fill_head("角色状态")
	if _fill_missing():
		return
	var char_: Character = shown_char()
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


## ---------- 实时：订什么（"该不该听"由 UI_View.sync_listening 判，这里只负责订）----------
## **把被看角色的所有状态都订上**——收起的段标题也写着 ✔/✘，照样要实时值
## （整块收起时也不退：那只是"暂时没看"，一展开就该是新的）。
func _listen(char_: Character) -> void:
	if char_.statuses == null:
		return
	for status_name in char_.statuses.statuses.keys():
		_subscribe(char_, str(status_name))


## 订阅一个状态的全部"会变的东西"（回调里就地重铺那一段）。订四~六条：
##   · `satisfied` / `unsatisfied`：状态**汇总结果**变了（段标题的 ✔/✘ 靠它）；
##   · `trigger_changed`（`Msg.listen_status_trigger_changed`）：状态**内部某条依赖**的触发情况变了——
##     **这条不能省**：依赖变了往往不改 satisfied（只按 Shift、没按回车 ⇒ Submit 仍不满足），
##     只听前两条的话"段里那些依赖行"会一直是旧值（实测就是这个现象）；
##   · 两种外部检测（按预设声明订）：瞬时 / 保持型的亮灭同样不一定改 satisfied。
## 用 lambda 而**不用 `Callable.bind`**：Callable 的 == 不比较绑定参数，退订时摘不掉
## （同 AutoSys._index_of 踩的那个坑）；lambda 不带绑定参数 ⇒ 同一个实例传回去就能摘掉（_subs 里存的正是它）。
func _subscribe(char_: Character, status_name: String) -> void:
	var on_hit: Callable = func(_msg): _on_status_changed(status_name)
	_subs.append([Msg.listen_status_satisfied(char_, status_name, on_hit), on_hit])
	var on_lost: Callable = func(_msg): _on_status_changed(status_name)
	_subs.append([Msg.listen_status_unsatisfied(char_, status_name, on_lost), on_lost])
	var on_dep: Callable = func(_msg): _on_status_changed(status_name)
	_subs.append([Msg.listen_status_trigger_changed(char_, status_name, on_dep), on_dep])
	var preset: StatusPreset = char_.statuses.statuses.get(status_name)
	if preset == null:
		return
	if preset.with_detect_transient:
		var on_t: Callable = func(_msg): _on_status_changed(status_name)
		_subs.append([Msg.listen_status_detected_transient(char_, status_name, on_t), on_t])
	if preset.with_detect_manual:
		var on_m: Callable = func(_msg): _on_status_changed(status_name)
		_subs.append([Msg.listen_status_detected_manual(char_, status_name, on_m), on_m])
		var on_u: Callable = func(_msg): _on_status_changed(status_name)
		_subs.append([Msg.listen_status_undetected_manual(char_, status_name, on_u), on_u])


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
	var char_: Character = shown_char()
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
		"children": [UIInteract_Fold.title_item(_section_title(preset, char_), not open_, _chars())],
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
		_row("Decl", "auto_reset=%s   match_any=%s   外部检测：瞬时=%s 保持型=%s"
			% [preset.auto_reset, preset.match_any, preset.with_detect_transient, preset.with_detect_manual]),
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
	if preset.with_detect_transient:
		var hit: bool = bool(preset._detect_transient_triggers.get(char_, false))
		out.append(_row("G_detect_t", "【外部检测（瞬时）】→ %s" % ("✔ 已触发" if hit else "✘ 未触发"),
			Color(0.55, 0.80, 0.55) if hit else Color(0.75, 0.55, 0.55)))
		total += 1
	if preset.with_detect_manual:
		var hit: bool = bool(preset._detect_manual_triggers.get(char_, false))
		out.append(_row("G_detect_m", "【外部检测（保持型）】→ %s" % ("✔ 已触发" if hit else "✘ 未触发"),
			Color(0.55, 0.80, 0.55) if hit else Color(0.75, 0.55, 0.55)))
		total += 1
	if total == 0:
		out.append(_row("NoDep", "（没有依赖声明——靠外部检测，或恒不满足）",
			Color(0.45, 0.48, 0.55)))
	return out


## 该状态当前是否满足（**按角色**查：`satisfied[char_]`，没记过当 false）。
static func _satisfied(preset: StatusPreset, char_: Character) -> bool:
	return bool(preset.satisfied.get(char_, false))


## 依赖条数（六组监听器 + 两种外部检测），只用于标题那行摘要。
static func _dep_count(preset: StatusPreset) -> int:
	var n: int = (1 if preset.with_detect_transient else 0) + (1 if preset.with_detect_manual else 0)
	for group in GROUPS:
		n += (preset.get(str(group[1])) as Array).size()
	return n


## 一条依赖的显示文本：`名字  条件 [阈值]`（如 `Health  > 50`、`Tick  Advance`、`Pointer 1 Hold  HOLD`）。
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


## （`_row`（只读文字行）与 `_brief`（值的短文本）这两个零件已挪到 `UI_View`：三个一览共用一份。
##   行不写 `font_size`：用全局默认字号（也是最小字号，见 SysCfg.ui_font_size_default）。）


## 看的是哪个角色 / 按路径取角色：都走 `UIBase.target_path("char")` / `target_object("char")`
## （与 UI_Shortcut 同一处实现，别在这儿再写一份）。

