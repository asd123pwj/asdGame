class_name UI_Skill
extends UI_View
## **角色技能一览（只读 + 实时）**：把某个角色**装着的技能**（`Character.skills.skills`，见
## Script/Character/Skill/Skill.md）逐条摆出来，外加一句"现在在不在执行队列里"
## （`Character.skills.skill_queue`，由 `SkillPreset` 的依赖状态进 / 出队）：
##   · **实现类**（`skill_name`，如 `Skill_Walk`）——顺带报"类没建出来"（类名写错时 `preset.skill` 是 null）；
##   · **依赖状态**（`dependence_status`，可写 `状态名@identity`）+ **现在满不满足**（✔/✘）——它就是"进 / 出队"的开关；
##   · **队列**：在不在队列里 + 逐帧驱动用的那份参数（队列里那份才是真的在用的）；
##   · **流水**（`Skills.history`，同交互那边）：加装 / 移除 / **执行**各一笔（到秒）。
##     技能每物理帧都在执行 ⇒ 流水那边按"n 秒内超过 m 次就每秒只记第一次"限流（见 ActionHistory），
##     所以"最近执行"最多每秒前进一格（**消息每帧照来，省掉的是绘制**——见下）；
##   · **参数**（`config`，注册时交给实现类的那个：数组，如 `[300]`）。
## 段标题是摘要：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 在队列 ｜ 最近执行 16:48:13）`
## ——收起时也看得出"跑没跑、跑到哪了"。
##
## **看哪个角色 / 铺 / 只重铺一段 / 订阅生命周期**这套骨架都在 `UI_View`（同交互一览，两边的
## 流水行、依赖解析、参数行都是它给的公共零件）。本元素只回答它那组钩子，外加"订什么"——
##   · 每条技能**依赖的那个状态**（`satisfied` / `unsatisfied`，与 `SkillPreset.listen` 进 / 出队看的是同一个节点）
##     ⇒ 那一段就地重铺，"在队列 / ✔✘"当场变；
##   · **任意技能**的通配 `Msg.listen_skill_any_changed`（增 / 删 / 执行，见 MessageHub）——
##     增 / 删 ⇒ 整块重铺；**执行 ⇒ 绝不重铺**（技能每物理帧都在执行，重铺就是 60 次/秒重建整段），
##     只把段标题那一行"最近执行"就地换掉（`UI_View._refresh_section_title`）。


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "角色技能"


func _missing_text() -> String:
	return "" if _all() != null else "这个角色还没有技能集合"


## **那张表**：一条技能一个条目。
func _keys() -> Array:
	var names_: Array = _all().skills.keys()
	names_.sort()
	return names_


func _count_text(n: int) -> String:
	return "共 %d 条技能（标题上的 ✔/✘、「在队列」与「最近执行」是实时的；点一条展开看实现类 / 依赖状态 / 队列 / 流水 / 参数）" % n


## 段标题：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 在队列 ｜ 最近执行 16:48:13）`。
## "最近执行"那段只在**执行过**时才出现（没跑过的不印一串没意义的字）。
func _title_of(key: String) -> String:
	var preset: SkillPreset = _preset(key)
	if preset == null:
		return key
	var char_: Character = shown_char()
	var act_note: String = ""
	var rec: Dictionary = _rec(key)
	if rec.has("act"):
		act_note = " ｜ 最近执行 %s" % str((rec["act"] as Dictionary).get("clock", ""))
	return "%s（%s ｜ 依赖：%s %s ｜ %s%s）" % [key, str(preset.skill_name),
		str(preset.dependence_status), "✔" if _dep_hit(char_, preset.dependence_status) else "✘",
		"在队列" if _in_queue(preset) else "不在队列", act_note]


## 段里的行：实现类 / 依赖状态（+ 解析到谁）/ 队列 / 流水（最后时间）/ 参数。
func _rows_of(key: String) -> Array:
	var preset: SkillPreset = _preset(key)
	if preset == null:
		return []
	var char_: Character = shown_char()
	var built: bool = preset.skill != null
	var in_q: bool = _in_queue(preset)
	var out: Array = [
		_row("Impl", "实现类：%s%s" % [str(preset.skill_name),
			"" if built else "　（**没建出来**：类名写错了吗？）"],
			Color(0.13, 0.13, 0.16) if built else Color(0.70, 0.20, 0.20)),
		_row("Dep", "依赖状态：%s　→　%s%s" % [str(preset.dependence_status),
			"✔ 满足" if _dep_hit(char_, preset.dependence_status) else "✘ 未满足",
			_resolve_note(char_, preset.dependence_status)]),
		_row("Queue", _queue_text(preset, in_q),
			Color(0.20, 0.52, 0.24) if in_q else Color(0.33, 0.39, 0.50)),
	]
	out.append_array(_history_rows(_rec(key)))          # 公共零件（UI_View）
	out.append_array(_config_rows(preset.config))       # 公共零件（UI_View）
	return out


## ---------- 实时：订"每条技能依赖的状态" + "任意技能"通配（骨架见 UI_View）----------
## 依赖那条**用原始依赖名**订（不自己解析）：这样与 `SkillPreset.listen` 进 / 出队看的是**同一个节点**，
## 带 `@identity` 的也照样能跟着身份换绑（那套迁移在 MessageHub 里）。
func _listen(char_: Character) -> void:
	for preset: SkillPreset in char_.skills.skills.values():
		var on_hit: Callable = func(_msg): _refresh_section(str(preset.name))
		_watch(Msg.listen_status_satisfied(char_, preset.dependence_status, on_hit), on_hit)
		var on_lost: Callable = func(_msg): _refresh_section(str(preset.name))
		_watch(Msg.listen_status_unsatisfied(char_, preset.dependence_status, on_lost), on_lost)
	var on_any: Callable = func(msg): _on_any(char_, msg)
	_watch(Msg.listen_skill_any_changed(char_, on_any), on_any)


## 技能被增 / 删 / 执行（通配消息，payload = `[技能名, 动作]`，见 `Msg.send_skill_any_changed`）：
##   · **执行（act）⇒ 只就地换标题那一行字**——技能**每物理帧**都在执行，这条消息就是每帧都来
##     （限流只做在流水那边，消息不省），整块或整段重铺代价太大；
##   · 增 / 删 ⇒ 成员真的变了，整块重铺（`reload` 会把原来展开的段展回来）。
func _on_any(_char: Character, msg: Variant) -> void:
	if msg is Array and (msg as Array).size() >= 2 and str((msg as Array)[1]) == "act":
		_refresh_section_title(str((msg as Array)[0]))
		return
	reload()


## ---------- 取数据 ----------
## 这个角色的技能集合（没有就给 null，`_missing_text` 靠它说话）。
func _all() -> Skills:
	var char_: Character = shown_char()
	return char_.skills if char_ != null else null


## 某条技能那份共享预设。
func _preset(key: String) -> SkillPreset:
	var all: Skills = _all()
	return all.skills.get(key) if all != null else null


## 某条技能的流水记录（`{add / remove / act: {clock, text}}`，没记过就是空字典）。
func _rec(key: String) -> Dictionary:
	var all: Skills = _all()
	return all.history.get_rec(key) if all != null else {}


## 这条技能现在在不在执行队列里。
## 队列的键就是**实现类实例**（`SkillBase`，一个预设一个 ⇒ 与 `preset.skill` 是同一个）。
func _in_queue(preset: SkillPreset) -> bool:
	return preset.skill != null and _all().skill_queue.has(preset.skill)


## 队列那一行：在队列里就把**逐帧驱动用的那份参数**也写出来（队列里那份才是真的在用的）。
func _queue_text(preset: SkillPreset, in_q: bool) -> String:
	if not in_q:
		return "队列：**不在**（依赖状态不满足时由 SkillPreset 自动出队）"
	return "队列：**在**（逐帧执行中，参数：%s）" % _brief(_all().skill_queue.get(preset.skill))
