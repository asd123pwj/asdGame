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
## **实时**：订两样——
##   · 每条技能**依赖的那个状态**（`satisfied` / `unsatisfied`，与 `SkillPreset.listen` 进 / 出队看的是同一个节点）
##     ⇒ 那一段就地重铺，"在队列 / ✔✘"当场变；
##   · **任意技能**的通配 `Msg.listen_skill_any_changed`（增 / 删 / 执行，见 MessageHub）——
##     增 / 删 ⇒ 整块重铺；**执行 ⇒ 绝不重铺**（技能每物理帧都在执行，重铺就是 60 次/秒重建整段），
##     只把段标题那一行"最近执行"就地换掉。
## 开着才订、关掉全退、重开订回（骨架见 UI_View）。

## 每条技能那一段：技能名 -> 段（UI_Panel）。依赖状态一变就就地重铺其中一段。
var _secs: Dictionary = {}
## 每段**标题元素**（`UIInteract_Fold.title_item` 建的那个）：技能名 -> UI_Label。
## 只在"执行时就地换标题那一行字"时用（执行每帧都来，不能重铺）；`_section` 里顺手取，`_before_fill` 清。
var _titles: Dictionary = {}
## 整块重铺前记下的"哪几段展开着"：`_fill` 按它一次建对（箭头与 collapsed 同时就位，
## 不必"先按收起建、再展回来"——那样箭头会与实际状态不一致）。
var _open_names: Dictionary = {}


## 清掉"技能名 → 段 / 标题"的索引（重铺时由 UI_View.reload 调）。
func _before_fill() -> void:
	_secs.clear()
	_titles.clear()


## 铺：抬头 → 取不到角色就说清怎么给 → 一行总计 → 每条技能一段。
func _fill() -> void:
	_fill_head("角色技能")
	if _fill_missing():
		return
	var char_: Character = shown_char()
	if char_.skills == null:
		add_child_element("NoSet", "UI_Label", {"content": "这个角色还没有技能集合"})
		return
	var dict: Dictionary = char_.skills.skills
	var names_: Array = dict.keys()
	names_.sort()
	add_child_element("Count", "UI_Label", {
		"content": "共 %d 条技能（标题上的 ✔/✘、「在队列」与「最近执行」是实时的；点一条展开看实现类 / 依赖状态 / 队列 / 流水 / 参数）" % names_.size(),
		"font_color": Color(0.55, 0.60, 0.70),
	})
	for skill_name in names_:
		_section(char_, dict[skill_name], null, _open_names.has(str(skill_name)))


## 一条技能 = 一段：标题是摘要，内容（每一行）写成 `items` ⇒ **展开才建**（同状态 / 交互一览）。
## `old` 给了 ⇒ **原地换掉它**（位置不动，见 UIBase.replace_child_element）。
## `open_` = 重铺时这一段原来展开没有：**标题的箭头与 collapsed 都要按它来**，再把 `items` 建回来。
func _section(char_: Character, preset: SkillPreset, old: UIBase = null, open_: bool = false) -> void:
	var sec_name: String = "S_" + str(preset.name)
	var cfg: Dictionary = {
		"size": [0, 0],
		"collapsed": not open_,                  # 默认收起：技能多的时候打开也不卡
		"items": _rows(char_, preset),
		"children": [UIInteract_Fold.title_item(_section_title(char_, preset), not open_, _chars())],
	}
	var sec: UIBase = replace_child_element(old, sec_name, "UI_Panel", cfg) if old != null \
		else add_child_element(sec_name, "UI_Panel", cfg)
	_secs[preset.name] = sec
	# 记下标题元素（此刻它的第一个子元素就是标题：`items` 要等展开才建）。
	# 执行时靠它就地换那一行字（每帧都来的东西，不能再重铺整段）。
	_titles[preset.name] = sec.children[0] if not sec.children.is_empty() else null
	if open_:
		UIInteract_Fold.fold(sec, false)         # 展开态：顺手把 items 建出来（fold 里做的就是这个）


## 段标题：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 在队列 ｜ 最近执行 16:48:13）`。
## "最近执行"那段只在**执行过**时才出现（没跑过的不印一串没意义的字）。
static func _section_title(char_: Character, preset: SkillPreset) -> String:
	var act_note: String = ""
	var rec: Dictionary = char_.skills.history.get_rec(str(preset.name))
	if rec.has("act"):
		act_note = " ｜ 最近执行 %s" % str((rec["act"] as Dictionary).get("clock", ""))
	return "%s（%s ｜ 依赖：%s %s ｜ %s%s）" % [str(preset.name), str(preset.skill_name),
		str(preset.dependence_status), "✔" if _dep_hit(char_, preset.dependence_status) else "✘",
		"在队列" if _in_queue(char_, preset) else "不在队列", act_note]


## 段里的行：实现类 / 依赖状态（+ 解析到谁）/ 队列 / 流水（最后时间）/ 参数。
func _rows(char_: Character, preset: SkillPreset) -> Array:
	var built: bool = preset.skill != null
	var in_q: bool = _in_queue(char_, preset)
	var out: Array = [
		_row("Impl", "实现类：%s%s" % [str(preset.skill_name),
			"" if built else "　（**没建出来**：类名写错了吗？）"],
			Color(0.75, 0.78, 0.85) if built else Color(0.85, 0.55, 0.55)),
		_row("Dep", "依赖状态：%s　→　%s%s" % [str(preset.dependence_status),
			"✔ 满足" if _dep_hit(char_, preset.dependence_status) else "✘ 未满足",
			_resolve_note(char_, preset.dependence_status)]),
		_row("Queue", _queue_text(char_, preset, in_q),
			Color(0.70, 0.82, 0.70) if in_q else Color(0.62, 0.68, 0.78)),
	]
	out.append_array(_history_rows(char_, preset))
	out.append_array(_config_rows(preset.config))
	return out


## 队列那一行：在队列里就把**逐帧驱动用的那份参数**也写出来（队列里那份才是真的在用的）。
static func _queue_text(char_: Character, preset: SkillPreset, in_q: bool) -> String:
	if not in_q:
		return "队列：**不在**（依赖状态不满足时由 SkillPreset 自动出队）"
	return "队列：**在**（逐帧执行中，参数：%s）" % _brief(char_.skills.skill_queue.get(preset.skill))


## 这条技能现在在不在执行队列里。
## 队列的键就是**实现类实例**（`SkillBase`，一个预设一个 ⇒ 与 `preset.skill` 是同一个）。
static func _in_queue(char_: Character, preset: SkillPreset) -> bool:
	return preset.skill != null and char_.skills.skill_queue.has(preset.skill)


## 流水那三行：加装 / 移除 / 执行（各是"最后一次"的时间，到秒）。
## 摆出来的理由：技能每物理帧都在跑，不看流水就只能看到"现在在不在跑"。
func _history_rows(char_: Character, preset: SkillPreset) -> Array:
	var rec: Dictionary = char_.skills.history.get_rec(str(preset.name))
	return [
		_row("Hist_add", "加装：%s" % _stamp(rec.get("add", null)), Color(0.62, 0.68, 0.78)),
		_row("Hist_remove", "移除：%s" % _stamp(rec.get("remove", null)), Color(0.62, 0.68, 0.78)),
		_row("Hist_act", "执行：%s" % _stamp(rec.get("act", null)), Color(0.70, 0.75, 0.62)),
	]


## ---------- 实时：订"每条技能依赖的状态" + "任意技能"通配（骨架见 UI_View）----------
## 依赖那条**用原始依赖名**订（不自己解析）：这样与 `SkillPreset.listen` 进 / 出队看的是**同一个节点**，
## 带 `@identity` 的也照样能跟着身份换绑（那套迁移在 MessageHub 里）。
func _listen(char_: Character) -> void:
	for preset: SkillPreset in char_.skills.skills.values():
		var on_hit: Callable = func(_msg): _on_dep_changed(char_, str(preset.name))
		_watch(Msg.listen_status_satisfied(char_, preset.dependence_status, on_hit), on_hit)
		var on_lost: Callable = func(_msg): _on_dep_changed(char_, str(preset.name))
		_watch(Msg.listen_status_unsatisfied(char_, preset.dependence_status, on_lost), on_lost)
	var on_any: Callable = func(msg): _on_any_skill(char_, msg)
	_watch(Msg.listen_skill_any_changed(char_, on_any), on_any)


## 某条技能的依赖状态变了 ⇒ **只重铺那一段**（"在队列 / ✔✘"当场变），并保持它原来展开没展开。
## 找不到那条技能（被删了）/ 还没铺过 ⇒ 整块重铺（成员变过，重铺最省事）。
func _on_dep_changed(char_: Character, skill_name: String) -> void:
	var preset: SkillPreset = char_.skills.skills.get(skill_name)
	if preset == null or not _secs.has(skill_name):
		reload()
		return
	var sec: UIBase = _secs[skill_name]
	var open_: bool = not bool(sec.config.get("collapsed", true))
	_section(char_, preset, sec, open_)


## 技能被增 / 删 / 执行（通配消息，payload = `[技能名, 动作]`，见 `Msg.send_skill_any_changed`）：
##   · **执行（act）⇒ 只就地换标题那一行字**——技能**每物理帧**都在执行，这条消息就是每帧都来
##     （限流只做在流水那边，消息不省），整块或整段重铺代价太大；
##   · 增 / 删 ⇒ 成员真的变了，整块重铺（`reload` 会把原来展开的段展回来）。
func _on_any_skill(char_: Character, msg: Variant) -> void:
	if msg is Array and (msg as Array).size() >= 2 and str((msg as Array)[1]) == "act":
		_on_act(char_, str((msg as Array)[0]))
		return
	reload()


## 执行一次 ⇒ 把标题上那句"最近执行"就地换掉（**不重铺**：这条消息可能来得很密）。
## 文本没变就不刷（同一秒里连来几次时省掉重画——流水到秒，这一句才真的挡得住）；
## `content` / `content_2` 两套一起改，否则下一次点收起 / 展开对调时会换出旧文字。
func _on_act(char_: Character, skill_name: String) -> void:
	if not _secs.has(skill_name):
		return
	var preset: SkillPreset = char_.skills.skills.get(skill_name)
	if preset == null:
		return
	var title: UIBase = _titles.get(skill_name)
	if not is_instance_valid(title):
		return
	var folded: bool = bool(_secs[skill_name].config.get("collapsed", true))
	var texts: Array = UIInteract_Fold.title_texts(_section_title(char_, preset), folded)
	if str(title.config.get("content", "")) == str(texts[0]):
		return
	title.config["content"] = texts[0]
	title.config["content_2"] = texts[1]
	title.refresh("content")


## 重铺前记下"哪几段展开着"（给 `_fill` 用）——
## 不然任何一次整块重铺（技能被增 / 删）都会把用户展开的段全收回去。
func reload() -> void:
	_open_names.clear()
	for key in _secs.keys():
		var sec: UIBase = _secs[key]
		if is_instance_valid(sec) and not bool(sec.config.get("collapsed", true)):
			_open_names[key] = true
	super.reload()
