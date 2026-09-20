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
##       "events": [[QName.mouseLeft, 'UIInteract.toggle_fold(self.parent)'
##           + '\vUtils.swap("self.config.content", "self.config.content_2")'
##           + '\vself.refresh("content")']],
##   }],
## 想"开出来就是收起的"：在 open 那一句后面接一条 `UIInteract.fold(UiSys.get_ui("名字"))`。
## 注意：收起期间**运行时新加的子元素不会自动跟着藏**——加完再调一次 fold 即可。


## 收起（collapsed = true）/ 展开（false）：设置 target 各子元素的可见性。
## 被谁用：配置里的事件指令（`UIInteract.fold(self.parent, true)`）、外部按登记名调。
static func fold(target: UIBase, collapsed: bool = true) -> void:
	var ui: UIBase = _as_ui(target, "fold")
	if ui == null:
		return
	ui.config["collapsed"] = collapsed
	_apply_children(ui, collapsed)


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
