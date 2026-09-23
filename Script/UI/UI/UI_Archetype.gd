class_name UI_Archetype
extends UI_View
## **角色原型一览（只读、不实时）**：把某个角色的**原型**摊开——它就是"这角色由哪些预设组成"的配方。
## 取法：`Character.archetype_type`（角色初始化的入口，见 `Character._init_from_archetype`）
## → `Archetype.get_(...)`，然后一个字段一段（见 `FIELDS`）：
##   `buffs / statuses / interactions / bodies / skills / collisions / inventories / shortcuts / packages`
## 段标题是 `字段（N 项）`，段里一行一个预设名。**默认摊开**（这表是个静态配方，收着看不出所以然；
## 空字段例外——收着省地方）。
##
## **为什么不用实时**：原型只在**角色初始化那一刻**生效一次，之后再改原型也不会回头动已经建好的角色
## ⇒ 本元素**不订任何消息**（`UI_View._listen` 留空，`_subs` 一直是空的），
## 铺的时候读一次 `Archetype.get_()`，点了 `[刷新]`（或换了看的角色）再读一次。
##
## 两件容易误会的事（也印在抬头那行）：
##   · **这份清单是"合并后"的**：`Archetype.get_` 第一次取时会把 `packages` 里各原型的东西并进来
##     （buffs 不去重、其余去重）⇒ `packages` 那一段只是"合并了哪几个包"的记录；
##   · 换人看：写 `content_cmd="@Char/兔子"` 再点 `[刷新]`。

## 要摊开的字段（顺序 = 显示顺序）。`behaviors` 在 `Archetype` 里已被注释掉，所以不列。
const FIELDS: Array[String] = [
	"buffs", "statuses", "interactions", "bodies", "skills",
	"collisions", "inventories", "shortcuts", "packages",
]


## 铺：抬头 → 取不到角色就说清怎么给 → 一行说明 → 一个字段一段。
func _fill() -> void:
	_fill_head("角色原型")
	if _fill_missing():
		return
	var char_: Character = shown_char()
	var type_name: String = str(char_.archetype_type)
	var archetype: Archetype = Archetype.get_(type_name)
	if archetype == null:
		add_child_element("NoArch", "UI_Label", {
			"content": "找不到原型「%s」——查一下 Archetype 有没有注册这个名字" % type_name,
			"font_color": Color(0.85, 0.55, 0.55),
		})
		return
	add_child_element("Note", "UI_Label", {
		"content": "原型：%s（只在角色**初始化时**装配一次，之后改原型不会回头动这个角色；下面是合并 packages 之后的清单）" % type_name,
		"font_color": Color(0.55, 0.60, 0.70),
	})
	for field in FIELDS:
		_section(field, archetype.get(field))


## 一段 = 一个字段：标题 `字段（N 项）`，内容一行一个预设名。
## **默认摊开**（有东西就摊开；空字段收着）——这是静态快照，重铺只发生在 `[刷新]` / 换人时。
func _section(field: String, value: Variant) -> void:
	var list: Array = value if value is Array else []
	var open_: bool = not list.is_empty()
	var rows: Array = []
	if list.is_empty():
		rows.append(_row("Empty", "（无）", Color(0.45, 0.48, 0.55)))
	else:
		for i in list.size():
			rows.append(_row("Item_%d" % i, "　· %s" % str(list[i])))
	var sec: UIBase = add_child_element("S_" + field, "UI_Panel", {
		"size": [0, 0],
		"collapsed": not open_,
		"items": rows,
		"children": [UIInteract_Fold.title_item("%s（%d 项）" % [field, list.size()], not open_, _chars())],
	})
	if open_:
		UIInteract_Fold.fold(sec, false)         # 摊开：顺手把 items 建出来（fold 里做的就是这个）
