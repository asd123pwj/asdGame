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
## ⇒ 本元素**不订任何消息**（不覆写 `UI_View._listen`，`_subs` 一直是空的），
## 铺的时候读一次 `Archetype.get_()`，点了 `[刷新]`（或换了看的角色）再读一次。
##
## 两件容易误会的事（也印在抬头下面那行）：
##   · **这份清单是"合并后"的**：`Archetype.get_` 第一次取时会把 `packages` 里各原型的东西并进来
##     （buffs 不去重、其余去重）⇒ `packages` 那一段只是"合并了哪几个包"的记录；
##   · 换人看：写 `content_cmd="@Char/兔子"` 再点 `[刷新]`。
##
## 骨架（抬头 / 一条一段 / 记住展开态 / 订阅生命周期）都在 `UI_View`：本元素只回答它那组钩子，
## 其中"默认摊开"是靠覆写 `_folded`。

## 要摊开的字段（顺序 = 显示顺序）。`behaviors` 在 `Archetype` 里已被注释掉，所以不列。
const FIELDS: Array[String] = [
	"buffs", "statuses", "interactions", "bodies", "skills",
	"collisions", "inventories", "shortcuts", "packages",
]


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "角色原型"


func _missing_text() -> String:
	if _arch() != null:
		return ""
	return "找不到原型「%s」——查一下 Archetype 有没有注册这个名字" % _type_name()


## **那张表**：一个字段一个条目（顺序 = FIELDS 的顺序，见上）。
func _keys() -> Array:
	return FIELDS


## 没有"总计"那行（原来就没有）——说明写在 `_notes()` 里。
func _count_text(_n: int) -> String:
	return ""


## 抬头下面那行说明。
func _notes() -> Array:
	return [["Note", "UI_Label", {
		"content": "原型：%s（只在角色**初始化时**装配一次，之后改原型不会回头动这个角色；下面是合并 packages 之后的清单）"
			% _type_name(),
		"font_color": COUNT_COLOR,
	}]]


## **默认摊开**（这表是静态快照，收着看不出所以然）；空字段例外——收着省地方。
func _folded(key: String) -> bool:
	return not _field(key).is_empty()


func _title_of(key: String) -> String:
	return "%s（%d 项）" % [key, _field(key).size()]


func _rows_of(key: String) -> Array:
	var list: Array = _field(key)
	if list.is_empty():
		return [_row("Empty", "（无）", Color(0.45, 0.48, 0.55))]
	var out: Array = []
	for i in list.size():
		out.append(_row("Item_%d" % i, "　· %s" % str(list[i])))
	return out


## ---------- 取数据 ----------
## 这个角色声明的原型名。
func _type_name() -> String:
	var char_: Character = shown_char()
	return str(char_.archetype_type) if char_ != null else ""


## 那份原型（没注册过就给 null，`_missing_text` 靠它说话）。`get_` 自己带缓存，随便调。
func _arch() -> Archetype:
	var type_name: String = _type_name()
	return Archetype.get_(type_name) if type_name != "" else null


## 原型里某个字段的那一串预设名（字段不是数组就当空）。
func _field(key: String) -> Array:
	var arch: Archetype = _arch()
	if arch == null:
		return []
	var value: Variant = arch.get(key)
	return value if value is Array else []
