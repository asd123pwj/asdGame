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
## **看哪个角色 / 铺 / 只重铺一段 / 订阅生命周期**这套骨架都在 `UI_View`：本元素只回答它那组钩子
## （抬头标题、缺系统那行、那张表、总计、每条怎么显示），外加"订什么"。
## 一个状态 = **一段可折叠分组**（默认收起）：标题给"满足 ✔/✘ + 依赖条数"一眼看全局；
## 展开才建每条依赖的行（`items` 按需建）——状态多的时候打开也不卡。
## **收起的段标题上也写着 ✔/✘ ⇒ 开着就把所有状态全订上**，不看段展开没展开。

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


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "角色状态"


func _missing_text() -> String:
	return "" if _all() != null else "这个角色还没有状态集合"


## **那张表**：每个状态一个条目（表里只存名字，条目现取现算，见 UI_View 的说明）。
func _keys() -> Array:
	var names_: Array = _all().statuses.keys()
	names_.sort()
	return names_


func _count_text(n: int) -> String:
	return "共 %d 个状态（点标题展开看依赖与触发；标题上的 ✔/✘ 是实时的）" % n


## 段标题：状态名 + 满足情况 + 依赖条数（一眼看全局的那行；**这一行是实时的**）。
func _title_of(key: String) -> String:
	var preset: StatusPreset = _preset(key)
	if preset == null:
		return key
	return "%s（%s｜依赖 %d 条）" % [key,
		"✔ 满足" if _satisfied(preset) else "✘ 未满足", _dep_count(preset)]


## 一段里的所有行：现状（满足 / 最近消息 / 三个开关）、每组依赖的组名、每条依赖"声明 → 触发真值"。
## 触发为真标绿、为假标灰——一眼看出"是哪一条没满足"。
func _rows_of(key: String) -> Array:
	var preset: StatusPreset = _preset(key)
	if preset == null:
		return []
	var char_: Character = shown_char()
	var sat: bool = _satisfied(preset)
	var out: Array = [
		_row("Now", "满足：%s" % ("✔" if sat else "✘"),
			Color(0.20, 0.52, 0.24) if sat else Color(0.62, 0.24, 0.24)),
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
			Color(0.33, 0.39, 0.50)))
		# **按角色取触发真值**：预设里那张表是"所有角色混在一起"的，这里只拿这个角色那一份
		var triggers: Dictionary = preset.get(str(group[2])).get(char_, {})
		var i: int = 0
		for lt: ListenType in listeners:
			var hit: bool = bool(triggers.get(lt.name, false))
			out.append(_row("L_%s_%d" % [str(group[0]), i], "%s   → %s"
				% [_dep_text(lt), "✔ 已触发" if hit else "✘ 未触发"],
				Color(0.20, 0.52, 0.24) if hit else Color(0.62, 0.24, 0.24)))
			total += 1
			i += 1
	if preset.with_detect_transient:
		var hit_t: bool = bool(preset._detect_transient_triggers.get(char_, false))
		out.append(_row("G_detect_t", "【外部检测（瞬时）】→ %s" % ("✔ 已触发" if hit_t else "✘ 未触发"),
			Color(0.20, 0.52, 0.24) if hit_t else Color(0.62, 0.24, 0.24)))
		total += 1
	if preset.with_detect_manual:
		var hit_m: bool = bool(preset._detect_manual_triggers.get(char_, false))
		out.append(_row("G_detect_m", "【外部检测（保持型）】→ %s" % ("✔ 已触发" if hit_m else "✘ 未触发"),
			Color(0.20, 0.52, 0.24) if hit_m else Color(0.62, 0.24, 0.24)))
		total += 1
	if total == 0:
		out.append(_row("NoDep", "（没有依赖声明——靠外部检测，或恒不满足）",
			Color(0.45, 0.48, 0.55)))
	return out


## ---------- 实时：订什么（"该不该听"由 UI_View.sync_listening 判）----------
## **把被看角色的所有状态都订上**——收起的段标题也写着 ✔/✘，照样要实时值
## （整块收起时也不退：那只是"暂时没看"，一展开就该是新的）。
func _listen(char_: Character) -> void:
	if char_.statuses == null:
		return
	for status_name in char_.statuses.statuses.keys():
		_subscribe(char_, str(status_name))


## 订阅一个状态的全部"会变的东西"（回调里就地重铺那一段，见 UI_View._refresh_section）。订四~六条：
##   · `satisfied` / `unsatisfied`：状态**汇总结果**变了（段标题的 ✔/✘ 靠它）；
##   · `trigger_changed`（`Msg.listen_status_trigger_changed`）：状态**内部某条依赖**的触发情况变了——
##     **这条不能省**：依赖变了往往不改 satisfied（只按 Shift、没按回车 ⇒ Submit 仍不满足），
##     只听前两条的话"段里那些依赖行"会一直是旧值（实测就是这个现象）；
##   · 两种外部检测（按预设声明订）：瞬时 / 保持型的亮灭同样不一定改 satisfied。
func _subscribe(char_: Character, status_name: String) -> void:
	var on_hit: Callable = func(_msg): _refresh_section(status_name)
	_watch(Msg.listen_status_satisfied(char_, status_name, on_hit), on_hit)
	var on_lost: Callable = func(_msg): _refresh_section(status_name)
	_watch(Msg.listen_status_unsatisfied(char_, status_name, on_lost), on_lost)
	var on_dep: Callable = func(_msg): _refresh_section(status_name)
	_watch(Msg.listen_status_trigger_changed(char_, status_name, on_dep), on_dep)
	var preset: StatusPreset = _preset(status_name)
	if preset == null:
		return
	if preset.with_detect_transient:
		var on_t: Callable = func(_msg): _refresh_section(status_name)
		_watch(Msg.listen_status_detected_transient(char_, status_name, on_t), on_t)
	if preset.with_detect_manual:
		var on_m: Callable = func(_msg): _refresh_section(status_name)
		_watch(Msg.listen_status_detected_manual(char_, status_name, on_m), on_m)
		var on_u: Callable = func(_msg): _refresh_section(status_name)
		_watch(Msg.listen_status_undetected_manual(char_, status_name, on_u), on_u)


## ---------- 取数据（一律按名字现取：预设是共享的，拿名字取永远拿到当前那份）----------
## 这个角色的状态集合（没有就给 null，`_missing_text` 靠它说话）。
func _all() -> Statuses:
	var char_: Character = shown_char()
	return char_.statuses if char_ != null else null


## 某个状态那份共享预设（声明与"按角色存的现状"都从它身上读）。
func _preset(status_name: String) -> StatusPreset:
	var all: Statuses = _all()
	return all.statuses.get(status_name) if all != null else null


## 该状态当前是否满足（**按角色**查：`satisfied[char_]`，没记过当 false）。
func _satisfied(preset: StatusPreset) -> bool:
	return bool(preset.satisfied.get(shown_char(), false))


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
