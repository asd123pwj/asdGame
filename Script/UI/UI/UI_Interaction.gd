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
## **看哪个角色 / 铺 / 只重铺一段 / 订阅生命周期**这套骨架都在 `UI_View`（同技能一览，两边的
## 流水行、依赖解析、参数行都是它给的公共零件）。本元素只回答它那组钩子，外加"订什么"——
##   · 每条交互**依赖的那个状态**（`listen_status_satisfied / unsatisfied`，用的就是
##     `InteractionPreset.listen` 那条依赖名 ⇒ 与"真的触发"完全同一个节点）⇒ 那一段就地重铺，✔/✘ 当场变；
##   · **任意交互**的通配 `Msg.listen_interaction_any_changed`（增 / 删 / 触发，见 MessageHub）——
##     增 / 删 ⇒ 整块重铺（成员真变了）；**触发 ⇒ 只重铺那一段**（不整块重铺，省得动到别的段与次序）。


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "角色交互"


func _missing_text() -> String:
	return "" if _all() != null else "这个角色还没有交互集合"


## **那张表**：一条交互一个条目。
func _keys() -> Array:
	var names_: Array = _all().interactions.keys()
	names_.sort()
	return names_


func _count_text(n: int) -> String:
	return "共 %d 条交互（点一条展开看实现类 / 依赖状态 / 参数；标题上的 ✔/✘ 是实时的）" % n


## 段标题：`名字（实现类 ｜ 依赖：状态名 ✔ ｜ 最近执行 14:03:21）`。
## 最后那段只在**触发过**时才出现（没跑过的交互不印一串没意义的字）。
func _title_of(key: String) -> String:
	var preset: InteractionPreset = _preset(key)
	if preset == null:
		return key
	var char_: Character = shown_char()
	var extra: String = ""
	var rec: Dictionary = _rec(key)
	if rec.has("act"):
		extra = " ｜ 最近执行 %s" % str((rec["act"] as Dictionary).get("clock", ""))
	return "%s（%s ｜ 依赖：%s %s%s）" % [key, str(preset.interaction_name),
		str(preset.dependence_status), "✔" if _dep_hit(char_, preset.dependence_status) else "✘", extra]


## 段里的行：实现类 / 依赖状态（+ 解析到谁）/ 流水（最后时间）/ 参数。
func _rows_of(key: String) -> Array:
	var preset: InteractionPreset = _preset(key)
	if preset == null:
		return []
	var char_: Character = shown_char()
	var built: bool = preset.interaction != null
	var out: Array = [
		_row("Impl", "实现类：%s%s" % [str(preset.interaction_name),
			"" if built else "　（**没建出来**：类名写错了吗？）"],
			Color(0.13, 0.13, 0.16) if built else Color(0.70, 0.20, 0.20)),
		_row("Dep", "依赖状态：%s　→　%s%s" % [str(preset.dependence_status),
			"✔ 满足" if _dep_hit(char_, preset.dependence_status) else "✘ 未满足",
			_resolve_note(char_, preset.dependence_status)]),
	]
	out.append_array(_history_rows(_rec(key)))          # 公共零件（UI_View）
	out.append_array(_config_rows(preset.config))       # 公共零件（UI_View）
	return out


## ---------- 实时：订"每条交互依赖的状态" + "任意交互"通配（骨架见 UI_View）----------
## 依赖那条**用原始依赖名**订（不自己解析）：这样与 `InteractionPreset.listen` 触发时看的**是同一个节点**，
## 带 `@identity` 的也照样能跟着身份换绑（那套迁移在 MessageHub 里）。
func _listen(char_: Character) -> void:
	for preset: InteractionPreset in char_.interactions.interactions.values():
		var on_hit: Callable = func(_msg): _refresh_section(str(preset.name))
		_watch(Msg.listen_status_satisfied(char_, preset.dependence_status, on_hit), on_hit)
		var on_lost: Callable = func(_msg): _refresh_section(str(preset.name))
		_watch(Msg.listen_status_unsatisfied(char_, preset.dependence_status, on_lost), on_lost)
	var on_any: Callable = func(msg): _on_any(char_, msg)
	_watch(Msg.listen_interaction_any_changed(char_, on_any), on_any)


## 交互被增 / 删 / 触发（通配消息，payload = `[交互名, 动作]`，见 `Msg.send_interaction_any_changed`）：
##   · **触发（act）⇒ 只重铺那一段**（保留展开态）——标题的"最近执行"与展开后的流水行当场变新。
##     不整块重铺：那会把其它段一起重建（以前就是这么写的 ⇒ "每次触发都把展开的段收回去"，
##     测试循环每秒触发一次，看着就是"展开不到一秒自动收回"）；
##   · 增 / 删 ⇒ 成员真的变了，整块重铺（`reload` 会把原来展开的段展回来）。
func _on_any(char_: Character, msg: Variant) -> void:
	if msg is Array and (msg as Array).size() >= 2 and str((msg as Array)[1]) == "act":
		_refresh_section(str((msg as Array)[0]))
		return
	reload()


## ---------- 取数据 ----------
## 这个角色的交互集合（没有就给 null，`_missing_text` 靠它说话）。
func _all() -> Interactions:
	var char_: Character = shown_char()
	return char_.interactions if char_ != null else null


## 某条交互那份共享预设。
func _preset(key: String) -> InteractionPreset:
	var all: Interactions = _all()
	return all.interactions.get(key) if all != null else null


## 某条交互的流水记录（`{add / remove / act: {clock, text}}`，没记过就是空字典）。
func _rec(key: String) -> Dictionary:
	var all: Interactions = _all()
	return all.history.get_rec(key) if all != null else {}
