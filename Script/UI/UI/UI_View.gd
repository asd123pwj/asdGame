class_name UI_View
extends UI_Panel
## **"看某个对象的一览"这类元素的共同底座**：`UI_Status`（状态）/ `UI_Shortcut`（快捷）/ `UI_Attr`（属性）都继承它。
## 三处本来各写一份的骨架收在这里，**差别只有两件事**：铺什么（`_fill`）、订什么（`_listen`）。
##
##   · **看哪个对象**：走 `UIBase.target_path("char")` / `target_object("char")` 那条通用规则
##     （查看项 `content_cmd`——自己的或外壳上写的——优先，其次本元素 config 的 `char`）。
##     本类把它固定成"看哪个**角色**"这一种用法：`shown_path()` / `shown_char()`，全项目只有这一处读 `char`。
##   · **铺内容**：`on_registered` 时**推迟一帧**铺（`open` 的临时配置是建完之后才 merge 上的，
##     登记那一刻还读不到）；`reload` 先清再铺（幂等，延迟调用可能晚到）；**换对象自动重铺**
##     （`refresh` 里比对 `_path_shown`）。
##   · **监听生命周期**：`_shown` + `on_shown` / `on_hidden` + `sync_listening()`——开着就订、
##     关掉全退（不把订阅留在消息系统里）、重开由 `on_shown` 订回来。
##     `_shown` **不看控件可见性**：整块收起时子元素是隐藏的，而"隐藏"与"被关掉"是两回事。
##
## **铺出来的块一律用 `replace_child_element` 原地换**：摘掉再加会把它排到最底下
## （"数据一变那行就跳到末尾"就是这么来的）。
## **回调一律用 lambda，别用 `Callable.bind`**：`Callable` 的 `==` 不比较绑定参数，退订时摘不掉
## （同 `AutoSys._index_of` 记的坑）。
##
## 子类只需要实现：`_fill()`（铺）、可选 `_before_fill()`（清自己的索引）、可选 `_listen(char_)`（订）。

## 铺过没有（只铺一次；重铺走 reload）。
var _built: bool = false
## 上次铺的时候看的是哪个角色：换了对象就重铺（见 refresh）。
var _path_shown: String = ""
## 面板现在是不是"被显示着"（由 on_shown / on_hidden 维护）。
var _shown: bool = false
## 当前订阅：`[[消息 ID, 回调], ...]`（退订两样都要，见 MsgBus.unlisten）。
var _subs: Array[Array] = []


## 看的那个角色的**路径 / 引用**（"看哪个角色"只有这一处写法）。
func shown_path() -> String:
	return target_path("char")


## 看的那个角色（读不到 / 不是角色都给 null，由 `_fill_missing` 铺一行提示）。
func shown_char() -> Character:
	return target_object("char") as Character


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


## 重铺（"[刷新]"那一行、以及"换了看的角色"时调它）：清掉铺出来的整棵子树再铺一遍。
## 顺序：清子元素 → 退订（重铺必然换一批订阅，先全退最省心）→ 子类清索引 → 记下看的谁 → 铺 → 按"该不该听"订回来。
func reload() -> void:
	if control == null:
		return                       # 已经被关了 / 被移除了（延迟调用可能晚到）
	clear_children()
	_unlisten_all()
	_before_fill()
	_path_shown = shown_path()
	_fill()
	sync_listening()


## 刷新：**看的角色换了就重铺**（谁把刷新传到本元素上就自愈；`_built` 之前只当普通刷新）。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if _built and control != null and shown_path() != _path_shown:
		reload()


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


## ---------- 铺的公共零件（三个一览抬头那两行、找不到角色那行、一行只读文字）----------
## 抬头：`<标题>：<看的对象>` + `[刷新]`（点它就是整块重读重铺）。
func _fill_head(title: String) -> void:
	add_child_element("Where", "UI_Label", {
		"content": "%s：%s" % [title, shown_path()],
		"font_color": Color(0.62, 0.68, 0.78),
	})
	add_child_element("Reload", "UI_Label", {
		"content": "[刷新]",
		"events": [[QName.mouseLeft, "@self.parent.reload()"]],
	})


## 取不到角色就铺一行红字说清该写什么；返回 true = 已经铺好提示，调用方直接 return。
## （不猜、不默认到某个角色——默认值写在预设里，见 UIPreset_Attr 的 `char`。）
func _fill_missing() -> bool:
	if shown_char() != null:
		return false
	add_child_element("None", "UI_Label", {
		"content": "找不到角色「%s」——写 char=\"@Char/SYS\" 这种注册名（指令路径）" % shown_path(),
		"font_color": Color(0.85, 0.55, 0.55),
	})
	return true


## 一行 `[名字, 元素类, 配置]`（行都是只读文字：要变就重铺那一段，别去改它的 config）。
static func _row(row_name: String, text: String, color: Color = Color(0.75, 0.78, 0.85)) -> Array:
	return [row_name, "UI_Label", {"content": text, "font_color": color}]


## 值的短文本：null 说"（无）"，太长截断（可能挂着一整个角色 / 字典）。
static func _brief(value: Variant) -> String:
	if value == null:
		return "（无）"
	var text: String = str(value)
	return text if text.length() <= 48 else text.substr(0, 48) + "…"


## ---------- 子类钩子 ----------
## 铺内容（铺出来的一律走 add_child_element / replace_child_element）。
func _fill() -> void:
	pass


## 换对象后、铺之前：清子类自己的索引（如"状态名 → 段"、"类别 → 段"、"快捷名 → 块"）。
func _before_fill() -> void:
	pass


## 订这个角色身上要实时跟的东西（**开着才调**；不订实时就不覆写）。
func _listen(_char: Character) -> void:
	pass
