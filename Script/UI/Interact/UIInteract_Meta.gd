class_name UIInteract_Meta
extends UIInteractBase
## **富文本链接**：`UI_Label` 的内核是 RichTextLabel，`[url=meta]文字[/url]` 的 meta 怎么变成行为。
##
## **meta = 事件名 + 冒号 + 一条指令**，例如：
##   [url=Pointer 1 Hold:UIInteract.drag(@host, @event)]拖动[/url]
##   [url=Pointer Move:<打开说明浮窗那条指令>]这段字[/url]     ← 内容用 `UIPreset_Basic.tip_hover_bind("文字")`
##                                                         拼（**别自己拼 open 指令**：延时与"一动就作废"都在那儿）
## 前缀写的就是**事件名**（`QName` 里那个，如 `QName.pointer1_hold` / `QName.pointer_move`）——
## 于是"哪个事件触发"和"meta 里写的前缀"是同一个词，**不必再维护 Click→某事件 那张映射表**；
## 事件名对不上就一个字都不执行（指针 1 按下不会去跑 `Pointer Move:` 那条）。
## 配置里拼这个形状用 `as_meta`（把"事件 + 指令"那一对拼成 `事件名:指令`，见它的说明）。
##
## 元素上把要认的事件都指向本指令，另有两条固定行为：
##   [QName.pointer1_hold, 'UIInteract.meta_event(@self)']    ← 点击类（按住）
##   [QName.pointer_move,  'UIInteract.meta_event(@self)']    ← 悬停类
##   [QName.pointer_exit,  'UIInteract.meta_event(@self)']    ← 移出元素：收掉它开的那几扇浮窗
##
## **为什么悬停要读 meta、而不是在元素上直接写 `pointer_enter → open`**：`pointer_enter` 只知道
## "指针进了这个元素"，不知道"在**哪段链接**上"——那个信息只有引擎的 meta 信号有（`UI_Label`
## 把它存进 `meta_hover`）。不读它的话，移到整行字的空白处也会弹，那是"这一行有说明"。
##
## **浮窗的收放规矩**（都在本文件，别在配置里各写一套 close）：
##   · 一个元素**同时只留一扇**：悬停到另一段字又开一扇时，先把本元素上一扇收掉；
##   · 指针**不在"有说明的那段字"上**（移到别的链接 / 这行的空白处）⇒ 收掉；
##   · 指针**移进浮窗自己身上不算离开**（浮窗是它的子窗，得能凑近看）——判据就是基类那条
##     `UIInteractBase._in_subtree`（与子菜单用的是同一条）；
##     ⚠️ **这一条对"悬停类事件"同样必须判**（不只是 `Pointer Exit`）：指针一落到浮窗上，事件是
##     从浮窗**冒泡**上来的（`UIBase.on_event`：本层没配就交给父级），而那一刻 `meta_hover` 天然是
##     null（指针不在链接上）⇒ 不判就会"鼠标一动，窗就被当成'离开链接'收掉"（实测踩过：
##     一段始终弹说明的链接，指针在它附近挪一下就闪断）；
##   · 指针移出整个元素（`Pointer Exit`）⇒ 全收。
##
## meta 从哪来：`UI_Label` 把 RichTextLabel 的两个 hover 信号（started / ended —— **这个版本没有
## "查指针下 meta"的方法**）记进 `meta_hover` 成员里。**要读就读悬停（meta_hover）、别读"最近点过的"**：
## 链接之外悬停一定是 null ⇒ 点空白文本不会把上一次的交互"粘"上来（实测踩过）。
## 事件机制与"点击折叠 / 关闭"完全同一套：配置 events → PointerDetect 派发 → 指令。

## 每个元素"上一次悬停到的那段链接的 meta"（`UI_Label` → meta 串 / null）：meta_event 靠它认"换链接了"，
## 换了就先收掉上一扇（"同时只留一扇"，见文件头）。**不在元素上另记"开出过哪几扇窗"**——那些窗就是
## 挂在 label 下面的子 UI，收的时候直接看 `label.children` 即可（见 _close_tips）。
static var _hover_meta: Dictionary = {}


## 把"事件 + 指令"那一对（`QName.UI_event_*` 那种）拼成 meta 的形状：`事件名:指令`。
## 配置里写正文时用它，一段链接就只填一个 `%s`：
##   "... [url=%s]拖动[/url] ..." % [UIInteract_Meta.as_meta(QName.UI_event_pointer1_drag_host)]
## 于是"这个事件 + 这条指令"是一整对（常用那几对已在 QName 里），不是散在两个常量里。
static func as_meta(bind: Array) -> String:
	if bind.size() < 2:
		return ""
	return "%s:%s" % [bind[0], bind[1]]


## 链接事件入口：按 meta 前缀判断"这次该不该执行"，该就把指令发出去；`Pointer Exit` 只管收窗。
## **它只做这一件事**：没落在链接上就什么都不做（"整块要有的默认行为"另绑一条事件即可，
## 见 UIBase.on_event 的"一个事件可以绑多条"与 UIInteract_Fold.title_item）。
## 被谁用：配置里三条事件都指它（见文件头）。
static func meta_event(rtl: UIBase) -> void:
	var label := _label(rtl)
	if label == null:
		return
	var event_name: String = str(CommandParser.event_name)
	if event_name == str(QName.pointer_exit):
		if not _hover_in_tips(label):
			_close_tips(label)               # 指针进了自己那扇浮窗 ⇒ 不算离开（见文件头）
		return
	# 指针在浮窗自己身上（浮窗是子窗）：不算离开链接，这一帧什么都不做——**点击也是点在窗上**。
	if _hover_in_tips(label):
		return
	var meta: Variant = label.meta_hover      # 当前悬停的那段链接（不在链接上 = null）
	# **换了链接（含离开链接 ⇒ null）⇒ 先把本元素上一扇浮窗收掉**：这就是"一个元素同时只留一扇"。
	# 判据是"悬停的那段 meta 变了"——同一段链接上指针挪动不算变（不然浮窗会被自己收掉，实测踩过）。
	if meta != _hover_meta.get(label):
		_hover_meta[label] = meta
		_close_tips(label)
	if not (meta is String):
		return
	var cmd: String = _pick(meta as String, event_name)
	if cmd == "":
		return                                # 这段字不归本事件管，这次不执行
	Msg.send_cmd(cmd)


## 从 meta 里挑出"这次该执行的那条指令"：**前缀就是事件名**，对不上 = 空串 = 这次不执行。
## **一段链接可以挂好几条**（一行一条），例如折叠箭头：按下折叠 ＋ 悬停弹说明——
##   事件名:指令
##   事件名:指令
## 行与行之间用**换行**分隔（不要用 `\v`：那是"一条指令里接多条子指令"，两种分隔各管一段，别混）。
## 事件名从指令系统拿（`CommandParser.event_name`，UIBase.on_event 派发前设好）——不靠调用方传：
## 同一个 `meta_event` 被好几条事件绑着调，它得自己认这次是谁。
static func _pick(meta: String, event_name: String) -> String:
	if event_name == "":
		return ""
	var prefix: String = event_name + ":"
	for line in meta.split("\n"):
		if line.begins_with(prefix):
			return line.substr(prefix.length())
	return ""


## 收掉本元素开出来的浮窗。**浮窗就是挂在 label 下面的子 UI**（`UIInteract.open` 的挂载点就是 @self，
## 见 UIPreset_Basic.tip_open_cmd）——所以"我开过哪几扇"不必另记一份表，看 `label.children` 即可：
## 一份数据一处真相，也躲开了"延时开窗时拿不到返回值"那个坑。收是**幂等**的（收一个已隐藏的窗 = 什么都不做）。
## 被谁用：meta_event（换链接 / 移出元素那几处）。
static func _close_tips(label: UI_Label) -> void:
	for ui in label.children.duplicate():
		if ui.control != null:
			UIInteract_OpenClose.close(ui)


## 指针是不是落在**本元素开的那几扇浮窗**上（含窗里的子元素）= 落在 label 某个子 UI 的子树里：
## 判据就是基类那条"指针在不在我这棵子树上"（`UIInteractBase._in_subtree`，与子菜单用的是同一条）。
## 为什么要这一条：浮窗虽是"子窗"，可它是**独立的一扇 UI**——指针从字上移到窗上，hover 就换人了，
## 元素会收到 `Pointer Exit`；不判这一下的话，刚想把说明凑近看，窗就自己关了（实测踩过）。
## 被谁用：meta_event（`Pointer Exit` 与悬停那几路）。
static func _hover_in_tips(label: UI_Label) -> bool:
	for ui in label.children:
		if _in_subtree(ui, PointerDetect.hover_ui):
			return true
	return false


## 元素本体（必须是 UI_Label —— 内核才是 RichTextLabel，才有 `[url]` 链接）；不是就给 null。
static func _label(rtl: UIBase) -> UI_Label:
	var ui := _as_ui(rtl, "meta_event")
	if ui == null:
		return null
	var label := ui as UI_Label
	if label == null:
		push_warning("UIInteract.meta_event:「%s」不是 UI_Label（内核得是 RichTextLabel 才有链接）" % ui.name)
	return label
