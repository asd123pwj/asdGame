class_name UI_Interaction
extends UI_View
## **角色交互一览（只读 + 实时）**：把某个角色**装着的交互**（`Character.interactions`，见
## Script/Character/Interaction/InteractionPreset.gd）逐条摆出来——每条一段，段里是这条交互的**声明**
## 加一句"现在能不能用"（依赖状态满不满足）：
##   · **实现类**（`interaction_name`，如 `Interaction_Attack`）——顺带报"类没建出来"
##     （类名写错时 `preset.interaction` 是 null，`InteractionPreset._get_interaction_by_name` 那边会 push_error）；
##   · **依赖状态**（`dependence_status`，可写 `状态名@identity`）+ **现在满不满足**（✔/✘）——
##     它就是"这条交互会不会被触发"的开关；带 `@identity` 时把"解析到了哪个角色"也写出来
##     （用 `Msg._resolve_target`，和 `InteractionPreset.listen` 那边同一套解析）；
##   · **参数**（`config`，注册时直接交给实现类的那个）：字典就一行一个键，其它类型一行说清；
##   · **流水**（`Interactions.history`）：加装 / 移除 / 触发各一笔（现实时间 + 游戏时间，都到秒）——
##     交互是"一帧事件"，跑过去就没了，摆出来才看得出**刚才到底触发没触发**。
## 段标题是摘要：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 最近执行 14:03:21）`——收起时也看得出"刚跑过没"。
##
## **实时**：订两样——
##   · 每条交互**依赖的那个状态**（`listen_status_satisfied / unsatisfied`，用的就是
##     `InteractionPreset.listen` 那条依赖名 ⇒ 与"真的触发"完全同一个节点）⇒ 那一段就地重铺，✔/✘ 当场变；
##   · **任意交互**的通配 `Msg.listen_interaction_any_changed`（增 / 删 / 触发，见 MessageHub）——
##     增 / 删 ⇒ 整块重铺（成员真变了）；**触发 ⇒ 不重铺**，只就地刷标题（和展开时的流水行），
##     省得每次触发都动展开态 / 次序。
## 开着才订、关掉全退、重开订回（骨架见 UI_View）。

## 每条交互那一段：交互名 -> 段（UI_Panel）。依赖状态一变就就地重铺其中一段。
var _secs: Dictionary = {}
## 整块重铺前记下的"哪几段展开着"：`_fill` 按它一次建对（箭头与 collapsed 同时就位，
## 不必"先按收起建、再展回来"——那样箭头会与实际状态不一致）。
var _open_names: Dictionary = {}


## 清掉"交互名 → 段"的索引（重铺时由 UI_View.reload 调）。
func _before_fill() -> void:
	_secs.clear()


## 铺：抬头 → 取不到角色就说清怎么给 → 一行总计 → 每条交互一段。
func _fill() -> void:
	_fill_head("角色交互")
	if _fill_missing():
		return
	var char_: Character = shown_char()
	if char_.interactions == null:
		add_child_element("NoSet", "UI_Label", {"content": "这个角色还没有交互集合"})
		return
	var dict: Dictionary = char_.interactions.interactions
	var names_: Array = dict.keys()
	names_.sort()
	add_child_element("Count", "UI_Label", {
		"content": "共 %d 条交互（点一条展开看实现类 / 依赖状态 / 参数；标题上的 ✔/✘ 是实时的）" % names_.size(),
		"font_color": Color(0.55, 0.60, 0.70),
	})
	for interaction_name in names_:
		_section(char_, dict[interaction_name], null, _open_names.has(str(interaction_name)))


## 一条交互 = 一段：标题是摘要，内容（每一行）写成 `items` ⇒ **展开才建**（同状态一览）。
## `old` 给了 ⇒ **原地换掉它**（位置不动，见 UIBase.replace_child_element）。
## `open_` = 重铺时这一段原来展开没有：**标题的箭头与 collapsed 都要按它来**，再把 `items` 建回来，
## 不然"重铺一次就把人展开的段收回去"（而且箭头还会和实际状态不一致）。
func _section(char_: Character, preset: InteractionPreset, old: UIBase = null, open_: bool = false) -> void:
	var sec_name: String = "S_" + str(preset.name)
	var cfg: Dictionary = {
		"size": [0, 0],
		"collapsed": not open_,                  # 默认收起：交互多的时候打开也不卡
		"items": _rows(char_, preset),
		"children": [UIInteract_Fold.title_item(_section_title(char_, preset), not open_, _chars())],
	}
	var sec: UIBase = replace_child_element(old, sec_name, "UI_Panel", cfg) if old != null \
		else add_child_element(sec_name, "UI_Panel", cfg)
	_secs[preset.name] = sec
	if open_:
		UIInteract_Fold.fold(sec, false)         # 展开态：顺手把 items 建出来（fold 里做的就是这个）


## 段标题：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 最近执行 14:03:21）`。
## 最后那段只在**触发过**时才出现（没跑过的交互不印一串没意义的字）。
static func _section_title(char_: Character, preset: InteractionPreset) -> String:
	var extra: String = ""
	var rec: Dictionary = char_.interactions.history.get_rec(str(preset.name))
	if rec.has("act"):
		extra = " ｜ 最近执行 %s" % str((rec["act"] as Dictionary).get("clock", ""))
	return "%s（%s ｜ 依赖：%s %s%s）" % [str(preset.name), str(preset.interaction_name),
		str(preset.dependence_status), "✔" if _dep_hit(char_, preset.dependence_status) else "✘", extra]


## 段里的行：实现类 / 依赖状态（+ 解析到谁）/ 流水（最后时间）/ 参数。
func _rows(char_: Character, preset: InteractionPreset) -> Array:
	var built: bool = preset.interaction != null
	var out: Array = [
		_row("Impl", "实现类：%s%s" % [str(preset.interaction_name),
			"" if built else "　（**没建出来**：类名写错了吗？）"],
			Color(0.75, 0.78, 0.85) if built else Color(0.85, 0.55, 0.55)),
		_row("Dep", "依赖状态：%s　→　%s%s" % [str(preset.dependence_status),
			"✔ 满足" if _dep_hit(char_, preset.dependence_status) else "✘ 未满足",
			_resolve_note(char_, preset.dependence_status)]),
	]
	out.append_array(_history_rows(char_, preset))
	out.append_array(_config_rows(preset.config))
	return out


## 流水那三行：加装 / 移除 / 执行（各是"最后一次"的时间）。
## 摆出来的理由：交互触发只持续一帧，不留痕就"看不出刚才发生过"。
func _history_rows(char_: Character, preset: InteractionPreset) -> Array:
	var rec: Dictionary = char_.interactions.history.get_rec(str(preset.name))
	return [
		_row("Hist_add", "加装：%s" % _stamp(rec.get("add", null)), Color(0.62, 0.68, 0.78)),
		_row("Hist_remove", "移除：%s" % _stamp(rec.get("remove", null)), Color(0.62, 0.68, 0.78)),
		_row("Hist_act", "执行：%s" % _stamp(rec.get("act", null)), Color(0.70, 0.75, 0.62)),
	]


## （`_stamp`（流水一笔）、`_dep_of` / `_dep_hit` / `_resolve_note`（依赖解析与满不满足）、
##   `_config_rows`（参数）这几个零件已挪到 `UI_View`：技能一览与这边**逐字相同**，共用一份。）


## ---------- 实时：订"每条交互依赖的状态" + "任意交互"通配（骨架见 UI_View）----------
## 依赖那条**用原始依赖名**订（不自己解析）：这样与 `InteractionPreset.listen` 触发时看的**是同一个节点**，
## 带 `@identity` 的也照样能跟着身份换绑（那套迁移在 MessageHub 里）。
func _listen(char_: Character) -> void:
	for preset: InteractionPreset in char_.interactions.interactions.values():
		var on_hit: Callable = func(_msg): _on_dep_changed(char_, str(preset.name))
		_watch(Msg.listen_status_satisfied(char_, preset.dependence_status, on_hit), on_hit)
		var on_lost: Callable = func(_msg): _on_dep_changed(char_, str(preset.name))
		_watch(Msg.listen_status_unsatisfied(char_, preset.dependence_status, on_lost), on_lost)
	var on_any: Callable = func(msg): _on_any_interaction(char_, msg)
	_watch(Msg.listen_interaction_any_changed(char_, on_any), on_any)


## 某条交互的依赖状态变了 ⇒ **只重铺那一段**，并保持它原来展开没展开。
## 找不到那条交互（被删了）/ 还没铺过 ⇒ 整块重铺（成员变过，重铺最省事）。
func _on_dep_changed(char_: Character, interaction_name: String) -> void:
	var preset: InteractionPreset = char_.interactions.interactions.get(interaction_name)
	if preset == null or not _secs.has(interaction_name):
		reload()
		return
	var sec: UIBase = _secs[interaction_name]
	var open_: bool = not bool(sec.config.get("collapsed", true))
	_section(char_, preset, sec, open_)


## 交互被增 / 删 / 触发（通配消息，payload = `[交互名, 动作]`，见 `Msg.send_interaction_any_changed`）：
##   · **触发（act）⇒ 只就地刷标题那一行字**（展开着的话连流水行一起刷）——不重铺，
##     省得每次触发都动展开态 / 次序（以前这里整块重铺，于是"每次触发都把展开的段收回去"；
##     测试循环每秒触发一次，看着就是"展开不到一秒自动收回"）；
##   · 增 / 删 ⇒ 成员真的变了，整块重铺（`reload` 会把原来展开的段展回来）。
func _on_any_interaction(char_: Character, msg: Variant) -> void:
	if msg is Array and (msg as Array).size() >= 2 and str((msg as Array)[1]) == "act":
		_on_act(char_, str((msg as Array)[0]))
		return
	reload()


## 触发一次 ⇒ **只就地重铺那一段**（保留它展开没展开）：标题的"最近执行"与展开后的流水行都当场变新。
## 不整块重铺：那会把其它段一起重建（以前就是这么写的 ⇒ "每次触发都把展开的段收回去"，
## 测试循环每秒触发一次，看着就是"展开不到一秒自动收回"）。
func _on_act(char_: Character, interaction_name: String) -> void:
	var preset: InteractionPreset = char_.interactions.interactions.get(interaction_name)
	if preset == null or not _secs.has(interaction_name):
		return
	var sec: UIBase = _secs[interaction_name]
	_section(char_, preset, sec, not bool(sec.config.get("collapsed", true)))


## 重铺前记下"哪几段展开着"（给 `_fill` 用）——
## 不然任何一次整块重铺（交互被增 / 删）都会把用户展开的段全收回去。
func reload() -> void:
	_open_names.clear()
	for key in _secs.keys():
		var sec: UIBase = _secs[key]
		if is_instance_valid(sec) and not bool(sec.config.get("collapsed", true)):
			_open_names[key] = true
	super.reload()
