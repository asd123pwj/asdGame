class_name UIInteract_Fold
extends UIInteractBase
## 收起 / 展开（"隐藏"而不是"关闭"）—— 设计见 Script/UI/UI.md 的"长内容与收回 / 展开"。
##
## **为什么在这儿而不是 UIBase 里**：这只是"把子元素 hide() / show() 一下"的**交互**，
## UIBase 不必为此记状态、也不必加方法（它越来越长，能挪出来的都挪出来）。
##
## 两个配置键（都在元素**自己**的 config 里，一份数据一处真相）：
##   collapsed       **父元素**上的收起态（bool，默认 false = 展开）
##   collapse_keep   **子元素**上的"收起时留着我"（bool，默认 false = 跟着收起）
## 于是"谁留下"由子元素自己声明（标题、收回按键把自己标上即可），**父元素不用维护名字清单**——
## 子元素改名、加删，都不用回头改父级配置。
##
## **收起后为什么不占屏幕**：不可见的子元素不参与容器布局 ⇒ 容器按内容收缩 ⇒
## "宽固定、高随内容"（size 里那一维为 0）的面板自己就变短了；**实例不销毁**，展开回来一切照旧。
## 对比 close：那是把整个 UI 隐藏（所以不能用来"只收起一段"）。
##
## 配置里怎么用（"收回按键"就是一条普通事件，再加一条文字对调）：
##   ["Title", "UI_Label", {"content": "标题", "collapse_keep": true}],          # 收起时留着
##   ["Fold", "UI_Label", {
##       "content": "▾ 收回", "content_2": "▸ 展开",
##       "collapse_keep": true,                                                    # 它自己也得留着
##       "events": [[QName.mouseLeft, 'UIInteract.toggle_fold(@self.parent)'
##           + '\vUtils.swap("@self.config.content", "@self.config.content_2")'
##           + '\v@self.refresh("content")']],
##   }],
## 想"开出来就是收起的"：在 open 那一句后面接一条 `UIInteract.fold(UISys.get_ui("名字"))`。
## 注意：收起期间**运行时新加的子元素不会自动跟着藏**——加完再调一次 fold 即可。


## 收起（collapsed = true）/ 展开（false）：设置 target 各子元素的可见性。
## **展开时顺手把"延后建"的子元素建出来**（`config["items"]`，格式同 `children`）：
## 大块内容（子UI一大串、嵌套编辑器）不必在打开时全铺，展开哪段才建哪段——这就是"折叠 + 按需加载"，
## 谁都能用（UI_Editor 的每一段就是靠它；不必为编辑器再写一个专用展开函数）。
## 被谁用：配置里的事件指令（`UIInteract.fold(@self.parent, true)`）、外部按登记名调、可折叠标题（toggle_fold）。
static func fold(target: UIBase, collapsed: bool = true) -> void:
	var ui: UIBase = _as_ui(target, "fold")
	if ui == null:
		return
	if not collapsed:
		_build_items(ui)
	ui.config["collapsed"] = collapsed
	_apply_children(ui, collapsed)


## 建 `config["items"]` 里声明的子元素（**只建一次**：built 标上就不再建）。
## 被谁用：fold（展开那一次）。
static func _build_items(ui: UIBase) -> void:
	if bool(ui.config.get("built", false)):
		return
	ui.config["built"] = true
	for item in ui.config.get("items", []):
		ui.add_child_element(str(item[0]), str(item[1]), item[2])


## 展开（= fold(target, false)）。
## 被谁用：配置里的"展开"指令、外部调用。
static func unfold(target: UIBase) -> void:
	fold(target, false)


## 收起 ↔ 展开翻转（同一个按键来回切，配置里不用判断现在是哪种）。
## 被谁用：配置里的"收回按键"。
static func toggle_fold(target: UIBase) -> void:
	var ui: UIBase = _as_ui(target, "toggle_fold")
	if ui == null:
		return
	fold(ui, not bool(ui.config.get("collapsed", false)))


## **可折叠标题**（片段构造器）：返回一条 `UI_Label` 配置——它自己既是标题又是收回按键。
## 点它 ⇒ 调 `toggle_cmd`（默认 `UIInteract.toggle_fold(@self.parent)`）收起 / 展开它**所在的那个分组**，
## 同时把箭头对调（`content` / `content_2` 两套文字，见 UI.md 的"开关式按钮"）。
## `collapse_keep: true` 是**它自己**声明"收起时留着我"——不标的话收起来后就再也点不回来了。
## `collapsed` = 那一段的初始状态（决定开头显示 ▸ 还是 ▾；两边对得上才不会"看着收起其实展开"）。
## `toggle_cmd` 给"展开时要顺带做别的"的场合用（默认那套已经够用：**展开时按需建 `config["items"]`**
## 也在 fold 里做了，所以不必再传别的）——别处照旧用默认值。
## **为什么放这儿而不是预设里**：它是"折叠"这个交互的一部分（收起时留我 / 箭头对调 / 点完刷新
## 都跟 fold 是一件事），放交互里谁都能用；预设只负责构造**自己**的 widgets，不该给别处提供零件。
## 想换样子（标题带底、或者另放一个 `[+]`/`[-]` 按钮）照抄这段改 `content` / `events` 即可。
static func title_item(title: String, collapsed: bool = false) -> Array:
	var shut: String = "▸ %s" % title
	var open_: String = "▾ %s" % title
	return ["Title", "UI_Label", {
		"content": shut if collapsed else open_,
		"content_2": open_ if collapsed else shut,
		"collapse_keep": true,
		"events": [[QName.mouseLeft,
			"UIInteract.toggle_fold(@self.parent)"
			+ '\vUtils.swap("@self.config.content", "@self.config.content_2")'
			+ '\v@self.refresh("content")']],
	}]


## 按收起态设置子元素可见性：
##   展开 ⇒ 每个子元素回到它自己 config["visible"]（各自"想不想显示"照旧）；
##   收起 ⇒ 只留**自己 config 里标了 `collapse_keep = true`** 的那些
##          （**收回按键要自己标上**，否则收起来就点不开了），其余隐藏。
## 本文件的私有助手（收起/展开只有这一处落地，别在别处再写一遍）。
static func _apply_children(ui: UIBase, folded: bool) -> void:
	for child in ui.children:
		if child.control == null:
			continue
		var want: bool = bool(child.config.get("visible", true))
		var kept: bool = bool(child.config.get("collapse_keep", false))
		child.control.visible = want and (not folded or kept)
