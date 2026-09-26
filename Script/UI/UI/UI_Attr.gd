class_name UI_Attr
extends UI_View
## **角色属性 / Buff 一览（只读 + 实时）**：把 `Character.attrs`（见 Script/Character/Attribute/Attributes.gd）铺出来。
## 一份 Attributes 有五样东西，本元素**按"类别"分组**把它们放在同一段里（点开一个类别就看到它的全部）：
##   · `attributes`：{类别: {值域: 值}}          → 段里「当前值」那一行（按 值域 顺序列）
##   · `attributes_before`：同结构，改动前的快照 → 段里「改动前」那一行（暂时没用上，但看得见）
##   · `attributes_changed_by_who / _how`：{类别: 谁 / 怎么改的} → 段里「最近改动」那一行
##   · `buffs`：{类别: {值域: {buff名: BuffPreset}}} → 段里「参与 Buff」**一行一个 buff**，把预设的字段摊开：
##     值域 / 名字 / `method + value`（`+10`、`=Health 的当前值`）/ `max_uses + uses[这个角色]`（已用几次、还剩几次）
## **按类别分而不是按那四个字典分**：它们是同一件事的四个视角，分四段反而要在四个地方来回找。
## **类别怎么来**：四个字典 + buffs 的键**取并集**——属性值是懒算的（`get_` 第一次取才算），
## 所以"有 buff 但还没算出属性"的类别也会列出来，不会漏。
##
## **段标题是摘要**（收起时也有信息）：`生命（CUR 2 ｜ buff 2 个 ｜ 改动：Init）`；
## 展开才建那几行（`items` 按需建，类别多也不卡）。
##
## **看哪个角色 / 铺 / 只重铺一段 / 订阅生命周期**这套骨架都在 `UI_View`：本元素只回答它那组钩子，
## 外加"订什么"——订两条就够：
##   · "任何属性变化"（`AnyChanged`，payload = 类别 ⇒ **只重铺那一段**）；
##   · "**任意 buff** 变化"（`Msg.listen_buff_any_changed`，通配节点，见 MessageHub）：buff 的具体消息是按
##     **名字**分节点的，没有通配时只能订"当前已知的那些"，运行期新加的收不到 ⇒ 它整块重铺。

## 值域的显示顺序（见 Enums.ValueType / StrValueType）。
const VALUE_ORDER: Array[int] = [
	Enums.ValueType.BASE,
	Enums.ValueType.CUR,
	Enums.ValueType.MIN,
	Enums.ValueType.FINAL,
	Enums.ValueType.MULTIPLIER,
]


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "角色属性"


func _missing_text() -> String:
	return "" if _all() != null else "这个角色还没有属性系统"


## **那张表**：一个类别一个条目。
func _keys() -> Array:
	return _categories()


func _count_text(n: int) -> String:
	return "共 %d 个类别 ｜ %d 个 buff（点类别展开看当前值 / 改动前 / 改动来源 / 参与 Buff）" \
		% [n, _buff_names().size()]


## 段标题：`类别（CUR 2 ｜ buff 2 个 ｜ 改动：Init）`——收起时也能一眼看出这个类别值多少。
func _title_of(key: String) -> String:
	var attrs: Attributes = _all()
	var parts: Array = []
	var values: Dictionary = attrs.attributes.get(key, {})
	if values.has(Enums.ValueType.CUR):
		parts.append("CUR %s" % str(values[Enums.ValueType.CUR]))
	var n: int = 0
	for by_name: Dictionary in (attrs.buffs.get(key, {}) as Dictionary).values():
		n += by_name.size()
	if n > 0:
		parts.append("buff %d 个" % n)
	var how: String = str(attrs.attributes_changed_by_how.get(key, ""))
	if how != "" and how != "Init":
		parts.append("改动：%s" % how)
	return key if parts.is_empty() else "%s（%s）" % [key, " ｜ ".join(parts)]


## 一段里的所有行：当前值 / 改动前 / 最近改动（三个视角各一行）+ 参与 Buff（**一行一个 buff**）。
func _rows_of(key: String) -> Array:
	var attrs: Attributes = _all()
	var out: Array = [
		_row("Now", "当前值：%s" % _value_text(attrs.attributes.get(key, {}))),
		_row("Before", "改动前：%s" % _value_text(attrs.attributes_before.get(key, {})),
			Color(0.33, 0.39, 0.50)),
		_row("Changed", "最近改动：谁=%s  怎么改=%s" % [
			_brief(RegSys.name_of(attrs.attributes_changed_by_who.get(key))),
			_brief(attrs.attributes_changed_by_how.get(key))]),
	]
	out.append_array(_buff_rows(key))
	return out


## ---------- 实时：订两条通配（骨架见 UI_View）----------
## · 任何属性变化（payload = 类别）⇒ 只重铺那一段；
## · **任意 buff** 变化（加 / 减 / 消耗 / 耗尽都在这个通配节点上）⇒ 整块重铺
##   （buff 一变成员与"参与 Buff"那行都会变，重铺最省事；这类事件不频繁）。
func _listen(char_: Character) -> void:
	var on_attr: Callable = func(msg): _refresh_section(str(msg))
	_watch(Msg.listen_any_attr_changed(char_, on_attr), on_attr)
	var on_buff: Callable = func(_msg): reload()
	_watch(Msg.listen_buff_any_changed(char_, on_buff), on_buff)


## ---------- 取数据 ----------
## 这个角色的属性系统（没有就给 null，`_missing_text` 靠它说话）。
func _all() -> Attributes:
	var char_: Character = shown_char()
	return char_.attrs if char_ != null else null


## 类别 = 四个字典与 buffs 的键**取并集**（属性是懒算的，"有 buff 还没算出值"的类别也要列）。
func _categories() -> Array:
	var attrs: Attributes = _all()
	var out: Array = []
	for dict: Dictionary in [attrs.attributes, attrs.attributes_before,
			attrs.buffs, attrs.attributes_changed_by_who, attrs.attributes_changed_by_how]:
		for key in dict.keys():
			if not out.has(key):
				out.append(key)
	out.sort()
	return out


## 所有 buff 名（`buffs` 是三层：类别 → 值域 → buff 名）。给"总计"那行用。
func _buff_names() -> Array:
	var out: Array = []
	for by_type: Dictionary in _all().buffs.values():
		for by_name: Dictionary in by_type.values():
			for buff_name in by_name.keys():
				if not out.has(buff_name):
					out.append(buff_name)
	return out


## **参与 Buff：一行一个**，把 `BuffPreset` 那几个字段摊开——
## `值域  名字  +10  次数：不限` / `值域  名字  =Health 的当前值  次数：已用 1 / 上限 2`。
## 对应：`value_type` / `name` / `method + value` / `max_uses + uses[这个角色]`；
## `category` 不用再写一遍——这一段本身就是那个类目（见 `_rows_of`）。
func _buff_rows(category: String) -> Array:
	var by_type: Dictionary = _all().buffs.get(category, {})
	var out: Array = []
	var n: int = 0
	for vt in VALUE_ORDER:
		var by_name: Dictionary = by_type.get(vt, {})
		for buff_name in by_name.keys():
			var buff: BuffPreset = by_name[buff_name]
			n += 1
			out.append(_row("B_%s_%d" % [_value_name(vt), n],
				"%s   %s   %s   %s" % [_value_name(vt), str(buff.name), _effect_text(buff), _uses_text(buff)],
				Color(0.36, 0.44, 0.28)))
	if out.is_empty():
		return [_row("NoBuff", "参与 Buff：（无）", Color(0.45, 0.48, 0.55))]
	out.push_front(_row("BuffHead", "参与 Buff（%d 个）" % n, Color(0.33, 0.39, 0.50)))
	return out


## 一个 buff "怎么改"：`+10`（整数）/ `=Health 的当前值`（值是字符串 = 另一个属性名，见 BuffPreset.value）。
static func _effect_text(buff: BuffPreset) -> String:
	var v: String = ("%s 的当前值" % str(buff.value)) if buff.value is String else str(buff.value)
	return "%s%s" % [_method_mark(buff.method), v]


## 一个 buff "用掉几次"：`max_uses <= 0` = 不限；否则 `已用 x / 上限 y（剩 z）`。
## `uses` 是**按角色**记的（见 BuffPreset.uses），所以这里要那个角色。
func _uses_text(buff: BuffPreset) -> String:
	if buff.max_uses <= 0:
		return "次数：不限"
	var used: int = int(buff.uses.get(shown_char(), 0))
	return "次数：已用 %d / 上限 %d（剩 %d）" % [used, buff.max_uses, maxi(0, buff.max_uses - used)]


## 修正方式的显示符号（Enums.StrModificationMethod；越界退回数字，不炸）。
static func _method_mark(method: Variant) -> String:
	if method is int and method >= 0 and method < Enums.StrModificationMethod.size():
		return Enums.StrModificationMethod[method]
	return str(method)


## `{值域: 值}` → 一行文本（按 VALUE_ORDER 顺序列 `值域名 值`；一个值域都没有就说"还没算出来"）。
static func _value_text(dict: Dictionary) -> String:
	if dict.is_empty():
		return "（还没算出来）"
	var parts: Array = []
	for vt in VALUE_ORDER:
		if dict.has(vt):
			parts.append("%s %s" % [_value_name(vt), str(dict[vt])])
	return "   ".join(parts) if not parts.is_empty() else "（空）"


## 值域名的显示文本（Enums.StrValueType 与枚举一一对应；越界就退回数字，不炸）。
static func _value_name(value_type: Variant) -> String:
	if value_type is int and value_type >= 0 and value_type < Enums.StrValueType.size():
		return Enums.StrValueType[value_type]
	return str(value_type)
