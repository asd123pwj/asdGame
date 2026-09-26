class_name UI_View
extends UI_Panel
## **"把一个对象的一条条东西摆出来"这类元素的共同底座**：`UI_Status`（状态）/ `UI_Shortcut`（快捷）/
## `UI_Attr`（属性）/ `UI_Interaction`（交互）/ `UI_Skill`（技能）/ `UI_Archetype`（原型）都继承它。
##
## 骨架全在这里，子类只回答"**摆哪些 / 每条怎么显示 / 订什么**"（就是下面那组钩子，都很短）——
## 于是"一条一条"的节奏全项目只有一份；加一个新的一览 = 实现那几个小函数 + 预设表加一行
## （见 `Config/UI/UIPreset_View.gd`）。
##
##   · **看哪个对象**：走 `UIBase.target_path("char")` / `target_object("char")` 那条通用规则
##     （查看项 `content_cmd`——自己的或外壳上写的——优先，其次本元素 config 的 `char`）。
##     本类把它固定成"看哪个**角色**"这一种用法：`shown_path()` / `shown_char()`，全项目只有这一处读 `char`。
##   · **那张表**：`_keys()` 返回要摆的条目名（顺序 = 显示顺序），**表里只存名字、条目现取现算**。
##     数据常常散在好几个成员里（如属性 = 四个字典 + buffs 的并集），而预设对象本身是共享的
##     （一个状态全项目一份）⇒ "名字 → 现读"永远拿到当前那份
##     （同 `StatusPreset._triggers` 把对象收进一张表统一遍历的思路）。
##   · **条目外壳只有一种**：一个**可折叠段**（`_section`，构造器在 `UIInteract_Fold.section_item`）——
##     标题常显、内容写成 `items` **展开才建**。快捷一览原来那种"常显块"已收进这一种。
##   · **铺内容**：`on_registered` 时**推迟一帧**铺（`open` 的临时配置是建完之后才 merge 上的，
##     登记那一刻还读不到）；`reload` 先清再铺（幂等，延迟调用可能晚到）；**换对象自动重铺**
##     （`refresh` 里比对 `_path_shown`）；**重铺会把原来展开的段展回来**。
##   · **局部刷新**（两种，按"变化有多频繁"选）：`_refresh_section(名)` 只重铺那一条（保留展开态）；
##     `_refresh_section_title(名)` 只换标题那行字（给"每帧都在来的"消息用，如技能执行）。
##   · **监听生命周期**：`_shown` + `on_shown` / `on_hidden` + `sync_listening()`——开着就订、
##     关掉全退（不把订阅留在消息系统里）、重开由 `on_shown` 订回来。
##     `_shown` **不看控件可见性**：整块收起时子元素是隐藏的，而"隐藏"与"被关掉"是两回事。
##
## **铺出来的块一律用 `replace_child_element` 原地换**：摘掉再加会把它排到最底下
## （"数据一变那行就跳到末尾"就是这么来的）。
## **回调一律用 lambda，别用 `Callable.bind`**：`Callable` 的 `==` 不比较绑定参数，退订时摘不掉
## （同 `AutoSys._index_of` 记的坑）。
##
## 子类要实现（都短）：`_head_title` / `_missing_text` / `_keys` / `_count_text` / `_title_of` / `_rows_of`，
## 可选 `_folded`（默认收起）/ `_notes`（条目之前的说明行）/ `_listen`（订实时，不实时就不写）。

## `_brief` 的截断阈值（字符）：只防"挂着一整个字典"这种无底洞，别拿它当"显示宽度"用
## （显示宽度是 `_chars()`，由行自己换行）。
const BRIEF_CHARS := 160

## 抬头下面那行总计的字色（"共 N 条…"那种）。五个一览原来各写一遍这个颜色值，收在这儿。
## **这一族"次要 / 强调"色都是深色版**：面板底是**浅色**图（`SysCfg.ui_background`）——
## 原来是给暗底挑的浅色，换浅底后统一压暗了一档（否则白底上发虚看不清）。
## 再调就改这些字面值（正文默认色由 `SysCfg.ui_font_color_default` 给，不必逐个写）。
const COUNT_COLOR := Color(0.33, 0.39, 0.50)

## 条目索引：条目名 -> 那一段（UI_Panel）。局部刷新（`_refresh_section`）靠它找"该重铺哪一段"。
var _secs: Dictionary = {}
## 条目名 -> 那一段的**标题元素**（`_section` 建段时顺手记）。
## 只在"只换标题那行字"时用（`_refresh_section_title`）。
var _titles: Dictionary = {}
## 整块重铺前记下的"哪几段展开着"：`_fill` 按它一次建对（箭头与 collapsed 同时就位，
## 不必"先按收起建、再展回来"——那样箭头会与实际状态不一致）。
var _open_names: Dictionary = {}
## 铺过没有（只铺一次；重铺走 reload）。
var _built: bool = false
## 上次铺的时候看的是哪个角色：换了对象就重铺（见 refresh）。
var _path_shown: String = ""
## 面板现在是不是"被显示着"（由 on_shown / on_hidden 维护）。
var _shown: bool = false
## 当前订阅：`[[消息 ID, 回调], ...]`（退订两样都要，见 MsgBus.unlisten）。
var _subs: Array[Array] = []


## ---------- 子类钩子：摆哪些 / 每条怎么显示 ----------
## 抬头的标题（`_fill_head` 的第一段）。
func _head_title() -> String:
	return ""


## 这一整个系统拿不到时铺哪行字（空串 = 不缺）。**在 `_fill_missing` 之后才调**，所以角色一定在。
func _missing_text() -> String:
	return ""


## **那张表**：要摆的条目名（顺序 = 显示顺序）。数据在哪、怎么筛、按什么排，都由子类现取现算。
func _keys() -> Array:
	return []


## 抬头下面那行总计（返回空串就不铺这一行）。
func _count_text(_n: int) -> String:
	return ""


## 条目之前的说明行（可选；每项是 `children` 那种 `[名字, 元素类, 配置]` 三元组）。
func _notes() -> Array:
	return []


## 该条目那一段的**标题摘要**（收起时也看得见信息的那行）。
func _title_of(_key: String) -> String:
	return str(_key)


## 该条目那一段里的**行**（走 `_row`；`items` 按需建 ⇒ 只在展开时才真的建出来）。
func _rows_of(_key: String) -> Array:
	return []


## 该条目段默认收不收（不覆写 = 收起；原型一览覆写成"有东西就摊开"）。
func _folded(_key: String) -> bool:
	return true


## ---------- 看哪个角色 ----------
## 看的那个角色的**路径 / 引用**（"看哪个角色"只有这一处写法）。
func shown_path() -> String:
	return target_path("char")


## 看的那个角色（读不到 / 不是角色都给 null，由 `_fill_missing` 铺一行提示）。
func shown_char() -> Character:
	return target_object("char") as Character


## ---------- 铺 ----------
## 登记完成 ⇒ 铺内容（铺出来的子元素要登记，而登记要拿父级名字 ⇒ 得等自己有名字，见 UIBase.on_registered）。
## **推迟一帧**：`open` 那次临时配置（`content_cmd=…`）是建完之后才 merge 上的。
func on_registered() -> void:
	if _built:
		return
	_built = true
	Callable(self, "reload").call_deferred()


## 被显示 / 被关掉：维护 `_shown` 并重算订阅（open 新建 / 复用两条路都会走到，见 UIBase.on_shown）。
func on_shown() -> void:
	_shown = true
	sync_listening()


func on_hidden() -> void:
	_shown = false
	_unlisten_all()


## 铺：抬头 → 取不到角色就说清怎么给 → 缺系统那行 → 一行总计 → 说明行 → **逐条一段**。
## **子类不要覆写它**：要改内容就改上面那组钩子（"一条一条"的节奏只有这一份）。
func _fill() -> void:
	_fill_head(_head_title())
	if _fill_missing():
		return
	var miss: String = _missing_text()
	if miss != "":
		add_child_element("NoSet", "UI_Label", {"content": miss})
		return
	var keys: Array = _keys()
	var count: String = _count_text(keys.size())
	if count != "":
		add_child_element("Count", "UI_Label", {"content": count, "font_color": COUNT_COLOR})
	for note: Array in _notes():
		add_child_element(str(note[0]), str(note[1]), note[2])
	for key in keys:
		_section(str(key), _title_of(str(key)), _rows_of(str(key)), null, _was_open(str(key)))


## 重铺（"[刷新]"那一行、以及"换了看的角色"时调它）：清掉铺出来的整棵子树再铺一遍。
## 顺序：先记"哪几段展开着" → 清子元素 → 退订（重铺必然换一批订阅，先全退最省心）→ 清索引 →
## 记下看的谁 → 铺 → 按"该不该听"订回来。
func reload() -> void:
	if control == null:
		return                       # 已经被关了 / 被移除了（延迟调用可能晚到）
	_remember_open()
	clear_children()
	_unlisten_all()
	_secs.clear()
	_titles.clear()
	_path_shown = shown_path()
	_fill()
	sync_listening()


## 刷新：**看的角色换了就重铺**（谁把刷新传到本元素上就自愈；`_built` 之前只当普通刷新）。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if _built and control != null and shown_path() != _path_shown:
		reload()


## ---------- 条目段 ----------
## 建 / 换一个条目段：**条目外壳只有这一种**（可折叠段：标题常显、内容写成 `items` 展开才建，
## 形状见 UIInteract_Fold.section_item）。
## `old` 给了 ⇒ **原地换掉它**（位置不动，见 UIBase.replace_child_element）——"某条数据变了就重铺那一段"用它；
## 直接"摘掉再加"会把这一段排到最底下（用户看着的次序不能自己动）。
## `open_` = 它新的一版该是展开着的（`_fill` 按 `_was_open` 传，局部刷新按当前状态传）：
## 建完立刻 `fold` 一下把 `items` 建出来，等价于"用户点开过"。
func _section(key: String, title: String, rows: Array, old: UIBase = null, open_: bool = false) -> UIBase:
	var item: Array = UIInteract_Fold.section_item("S_" + key, title, rows, not open_, _chars())
	var sec: UIBase = replace_child_element(old, str(item[0]), str(item[1]), item[2]) if old != null \
		else add_child_element(str(item[0]), str(item[1]), item[2])
	_secs[key] = sec
	# 记下标题元素（此刻它的第一个子元素就是标题：`items` 要等展开才建）——"只换标题那行字"要用它。
	_titles[key] = sec.children[0] if not sec.children.is_empty() else null
	if open_:
		UIInteract_Fold.fold(sec, false)
	return sec


## 记下"哪几段现在展开着"（给 `_fill` 用）——不然一次整块重铺就把用户展开的段全收回去。
func _remember_open() -> void:
	_open_names.clear()
	for key in _secs.keys():
		var sec: UIBase = _secs.get(key)
		if is_instance_valid(sec) and not bool(sec.config.get("collapsed", true)):
			_open_names[key] = true


## 这一段上一次是展开着的吗（`_fill` 建段时用它）。
func _was_open(key: String) -> bool:
	return _open_names.has(key)


## 某一条的数据变了 ⇒ **只重铺那一段**（保留它原来展开没展开）；那条已经不在了 ⇒ 整块 `reload`。
## 为什么整段重铺：一次变化往往连"标题、好几行"一起变，就地改每一行要写一堆映射；
## 而段里的行只在展开时才有（很少），重铺一段很便宜。
## 被谁用：各一览的监听回调。
func _refresh_section(key: String) -> void:
	var sec: UIBase = _secs.get(key)
	if not is_instance_valid(sec) or not _keys().has(key):
		reload()
		return
	_section(key, _title_of(key), _rows_of(key), sec, not bool(sec.config.get("collapsed", true)))


## **只把标题那行字换掉**（不重铺整段）：给"每帧都在来的"消息用（如技能执行——重铺扛不住那个频率）。
## 文本没变就不刷（同一秒里连来几次时省掉重画）；`content` / `content_2` **两套一起改**，
## 否则下一次点收起 / 展开对调时会换出旧文字（见 UIInteract_Fold.title_texts）。
## 被谁用：UI_Skill 的"执行"那一路。
func _refresh_section_title(key: String) -> void:
	var sec: UIBase = _secs.get(key)
	var title: UIBase = _titles.get(key)
	if not is_instance_valid(sec) or not is_instance_valid(title):
		return
	var texts: Array = UIInteract_Fold.title_texts(_title_of(key), bool(sec.config.get("collapsed", true)))
	if str(title.config.get("content", "")) == str(texts[0]):
		return
	title.config["content"] = texts[0]
	title.config["content_2"] = texts[1]
	title.refresh("content")


## ---------- 监听 ----------
## 按"现在该不该听"重算订阅（**幂等**，随便调）：没被显示 / 没角色 ⇒ 全退；否则交给子类 `_listen`。
func sync_listening() -> void:
	_unlisten_all()
	var char_: Character = shown_char()
	if not _shown or char_ == null:
		return
	_listen(char_)


## 退掉所有订阅（幂等；空表也安全）。
func _unlisten_all() -> void:
	for sub: Array in _subs:
		MsgBus.unlisten(sub[0], sub[1])
	_subs.clear()


## 订一条消息并记下来（**必须记下来才退得掉**，见 MsgBus.unlisten）。
func _watch(msg_id: String, callback: Callable) -> void:
	_subs.append([msg_id, callback])


## 订这个角色身上要实时跟的东西（**开着才调**；回调里用 `_refresh_section` / `_refresh_section_title` 跟上）。
## 不订实时就不覆写。
func _listen(_char: Character) -> void:
	pass


## ---------- 铺的公共零件（抬头那两行、找不到角色那行、一行只读文字）----------
## 本视图"一行有多宽"（**字符数**，中文算 2）：面板 config 里的 `max_chars`，没写就用全局默认。
## **行、段标题、输入框都用它**——三者同宽才不会出现"标题把面板撑到内容的两三倍宽、
## 内容那栏却早早换了行"（实测踩过）。想逐个面板调就在那个预设里写 `max_chars`
## （如看板里每一格写按格子宽反推的那个值，见 UIPreset_View.CELL_CHARS）。
func _chars() -> int:
	return int(config.get("max_chars", SysCfg.ui_view_chars))


## 抬头：`<标题>：<看的对象>` + `[刷新]`（点它就是整块重读重铺）。
## 宽度不用在这儿写：文字行统一由 add_child_element 那个覆写补上 `_chars()`（见它）。
func _fill_head(title: String) -> void:
	add_child_element("Where", "UI_Label", {
		"content": "%s：%s" % [title, shown_path()],
		"font_color": Color(0.33, 0.39, 0.50),
	})
	add_child_element("Reload", "UI_Label", {
		"content": "[刷新]",
		"events": [[QName.pointer1_hold, "@self.parent.reload()"]],
	})


## 取不到角色就铺一行红字说清该写什么；返回 true = 已经铺好提示，调用方直接 return。
## （不猜、不默认到某个角色——默认值写在预设里，见 UIPreset_View 的 `char` 那一列。）
func _fill_missing() -> bool:
	if shown_char() != null:
		return false
	add_child_element("None", "UI_Label", {
		"content": "找不到角色「%s」——写 char=\"@Char/SYS\" 这种注册名（指令路径）" % shown_path(),
		"font_color": Color(0.70, 0.20, 0.20),
	})
	return true


## 覆写：本视图铺出来的**文字行**统一带上宽度上限（`max_chars` = `_chars()`，行自己写了就不覆盖）。
## **为什么要覆写而不是逐个补**：漏一处就有一个长标签把整块面板撑开——
## 实测漏过 `Count`（"共 N 条…"那句）、`Note` 这些**不是通过 `_row` 铺的**行。
## 只认 `UI_Label`：段/块那种嵌套面板要按自己的内容定宽（它们里面的行有自己的上限，见 `_row` / `title_item`）。
## 被谁用：`_fill`（以及各钩子铺的行）。
func add_child_element(child_name: String, ui_class: String, child_config: Dictionary = {}) -> UIBase:
	if ui_class == "UI_Label" and not child_config.has("max_chars"):
		var chars: int = _chars()
		if chars > 0:
			child_config["max_chars"] = chars
	return super.add_child_element(child_name, ui_class, child_config)


## 一行 `[名字, 元素类, 配置]`（行都是只读文字：要变就重铺那一段，别去改它的 config）。
## **宽度取本视图的 `_chars()`**（字符数）：文字元素配了上限就自动换行、高度按折行数算，
## 于是"长行不再把面板撑开"，而是自己折成几行（这就是"标题与内容同宽"的落点）。
## **不用配高度**：`UI_Label` 的高 = 折行数 × 行高（见它的 `_text_height`）。
## **是实例方法**（要读本视图的 config）——调它的一定是实例方法（`_rows_of`）。
func _row(row_name: String, text: String, color: Color = Color(0.13, 0.13, 0.16)) -> Array:
	return [row_name, "UI_Label", {"content": text, "font_color": color, "max_chars": _chars()}]


## 值的短文本：null 说"（无）"；**太长只截一刀**（值可能挂着一整个角色 / 字典，那是无底洞）。
## 截的阈值给得比"一栏宽"（`_chars()`，默认 48 字符）宽得多：**长值该由行自己换行显示**，
## 不该在这里就被截掉——以前这里截 48，正好等于一栏宽 ⇒ 长值既被截又被折，白丢信息。
static func _brief(value: Variant) -> String:
	if value == null:
		return "（无）"
	var text: String = str(value)
	return text if text.length() <= BRIEF_CHARS else text.substr(0, BRIEF_CHARS) + "…"


## ---------- 铺的公共零件（依赖 / 流水 / 参数：交互一览与技能一览共用）----------
## 依赖声明（可写 `状态名@identity`）→ `[解析到的角色, 纯状态名]`。
## 与各预设注册监听时用的是**同一套解析**（`Msg._resolve_target`）⇒ "一览里看到的 ✔/✘"就是"真的触发 / 进出队时看的那个"。
## 被谁用：UI_Interaction / UI_Skill（依赖那一行与标题上的 ✔/✘）。
static func _dep_of(char_: Character, dependence_status: String) -> Array:
	return Msg._resolve_target(char_, dependence_status)


## 这条依赖现在满足吗（按**解析到的那个角色**算；没装过 / 没算出都算未满足）。
## 被谁用：同上。
static func _dep_hit(char_: Character, dependence_status: String) -> bool:
	var resolved: Array = _dep_of(char_, dependence_status)
	var target: Character = resolved[0]
	if target == null or target.statuses == null or not target.statuses.check_exist(str(resolved[1])):
		return false
	return target.statuses.check_satisfied(str(resolved[1]))


## 依赖里写了 `@identity` 时，把"解析到了谁"写出来（没写就没这段）。被谁用：同上。
static func _resolve_note(char_: Character, dependence_status: String) -> String:
	var raw: String = str(dependence_status)
	if not raw.contains("@"):
		return ""
	var resolved: Array = _dep_of(char_, dependence_status)
	return "　（%s@%s → %s）" % [str(resolved[1]), raw.split("@")[1],
		_brief(RegSys.name_of(resolved[0]))]


## 参数 `config` 那几行：字典一行一个键；其它类型（如技能那种数组）一行说清；null 说"（无）"。
## 键名与值都用 `_brief` 截断（参数里可能挂着字典 / 数组 / 角色）。
## 被谁用：UI_Interaction（字典参数）/ UI_Skill（数组参数）。
## **是实例方法**：只是因为它调的 `_row` 要读本视图的宽度（见 `_row` / `_chars`）。
## （下面到文件末尾：参数是 Variant，取键取值本来就要转一次——显式压掉这两类告警，与 UI_Panel 同一写法。）
@warning_ignore_start("unsafe_cast", "unsafe_method_access")
func _config_rows(cfg: Variant) -> Array:
	if cfg == null:
		return [_row("Cfg", "参数：（无）", Color(0.45, 0.48, 0.55))]
	if not (cfg is Dictionary):
		return [_row("Cfg", "参数：%s" % _brief(cfg), Color(0.33, 0.39, 0.50))]
	var out: Array = [_row("Cfg", "参数（%d 项）" % (cfg as Dictionary).size(),
		Color(0.33, 0.39, 0.50))]
	var i: int = 0
	for key in (cfg as Dictionary).keys():
		out.append(_row("Cfg_%d" % i, "　%s = %s" % [str(key), _brief(cfg[key])]))
		i += 1
	return out


## 流水那三行（加装 / 移除 / 执行，各是"最后一次"的时间）：交互与技能**逐字相同**，所以收在这儿。
## 摆出来的理由：交互只持续一帧、技能每物理帧都在跑——不留痕就"看不出刚才发生过"。
## 被谁用：UI_Interaction / UI_Skill。
func _history_rows(rec: Dictionary) -> Array:
	return [
		_row("Hist_add", "加装：%s" % _stamp(rec.get("add", null)), Color(0.33, 0.39, 0.50)),
		_row("Hist_remove", "移除：%s" % _stamp(rec.get("remove", null)), Color(0.33, 0.39, 0.50)),
		_row("Hist_act", "执行：%s" % _stamp(rec.get("act", null)), Color(0.36, 0.44, 0.28)),
	]


## 一笔流水 -> 给人看的文本：`14:03:21（元年正月初一 子时）`；没记过 -> `（还没）`。
## 前面是**现实墙上时钟**（"具体时间"，到秒——流水按"n 秒内超过 m 次就每秒只记第一次"限流，
## 最快也是每秒一笔，再细没意义），括号里是**游戏时间**。
## 被谁用：`_history_rows`。
static func _stamp(entry: Variant) -> String:
	if not (entry is Dictionary):
		return "（还没）"
	return "%s（%s）" % [str(entry.get("clock", "")), str(entry.get("text", ""))]
@warning_ignore_restore("unsafe_cast", "unsafe_method_access")
