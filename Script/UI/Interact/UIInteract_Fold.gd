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
##       "events": [[QName.pointer1_hold, 'UIInteract.toggle_fold(@self.parent)'
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
	# **收起 / 展开都会改变内容，所以要重算一次尺寸**：内容是"长出来的"面板靠内容盒的最小尺寸信号
	# 自己就收缩了（见文件头）——但**网格面板**的内容盒是个普通 Control（不发那个信号），
	# 光等信号收不了，还会剩一大块空底（见 UIBase._fit_size 的"收起时高度让给内容"）。
	# 重算一次是幂等的：内容为准的面板算出来的还是同一个尺寸。
	ui._fit_size()


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
## 箭头那段是链接，meta 里带着"按下 ⇒ `UIInteract.toggle_fold(@self.parent)` ＋ 对调两套文字 ＋ 刷新"
## （那对绑定在 `QName.UI_event_pointer1_fold_parent`，见 `LINK_FOLD`）——所以只折它**所在的那个分组**，
## 并把箭头 `▾ ⇄ ▸` 对调（`content` / `content_2` 两套文字，见 UI.md 的"开关式按钮"）。
## `collapse_keep: true` 是**它自己**声明"收起时留着我"——不标的话收起来后就再也点不回来了。
## `collapsed` = 那一段的初始状态（决定开头显示 ▸ 还是 ▾；两边对得上才不会"看着收起其实展开"）。
## （"展开时按需建 `config["items"]`"那件事也在 fold 里做了，标题这套不用再传别的参数。）
## **为什么放这儿而不是预设里**：它是"折叠"这个交互的一部分（收起时留我 / 箭头对调 / 点完刷新
## 都跟 fold 是一件事），放交互里谁都能用；预设只负责构造**自己**的 widgets，不该给别处提供零件。
## 想换样子（标题带底、或者另放一个 `[+]`/`[-]` 按钮）照抄这段改 `content` / `events` 即可。
## **标题条顶满整块面板**（`fill_width: true`，见 UI_Label 的宽度三档）：容器给多宽就占多宽
## （窗口标题栏那种观感），而它**自己那份宽仍算数**（当最小宽）⇒ 不会出现"面板被标题缩成一条"。
## `chars` 给了（>0）就给标题**限宽**（`max_chars`，字符数）：它既是"标题最宽到哪儿"、
## 也是上面说的**最小宽**（短标题的标题条不会长成一大段空白）；不给就按文字自然宽。
## （不限宽的话它会把整块面板撑到内容那栏的两三倍宽——实测踩过，所以这个上限留着；顶满只是"往上长"。）
## 点击行为：**按住就拖；若指针正停在箭头那段链接上，再跑那段链接自己的指令（折叠）**。
## 两条都是普通绑定、都挂在"按下"这一个事件上（一个事件可以绑多条，见 UIBase.on_event）——
## **没有一个"又折叠又拖动"的合成函数**：要拖动就直接写拖动，要折叠就写在那段 `[url]` 的 meta 里。
## （点在箭头上时拖动也会登记，但那是"按住"类交互：没位移就等于什么都没发生。）
## 被谁用：各一览（传自己的 `_chars()`，见 UI_View）、各预设（传 `SysCfg.ui_view_chars`）。
static func title_item(title: String, collapsed: bool = false, chars: int = 0) -> Array:
	var texts: Array = title_texts(title, collapsed)
	var cfg: Dictionary = {
		"content": texts[0],
		"content_2": texts[1],
		"fill_width": true,                          # **顶满容器**：标题条横跨整块面板（见 UI_Label）
		"collapse_keep": true,                       # 收起时留着我——**别删**，不标的话收起来就再也点不回来了
		# 独立绑定（都执行）：① 按住拖 `@host`（窗口；拖"竖排里的一段"会被布局盖回去，没意义）；
		# ② 按"指针下那段链接"跑它自己的指令——箭头那段链接挂着折叠与悬停说明（见 _sym_meta）；
		# ③ 指针一动（含悬停）也跑一遍：**说明浮窗就是靠它开的**（落在箭头外则收掉，见 UIInteract_Meta）；
		# ④ 移出标题把说明浮窗收掉。
		"events": [
			QName.UI_event_pointer1_drag_host,
			[QName.pointer1_hold, 'UIInteract.meta_event(@self)'],
			[QName.pointer_move, 'UIInteract.meta_event(@self)'],
			[QName.pointer_exit, 'UIInteract.meta_event(@self)'],
		],
	}
	if chars > 0:
		cfg["max_chars"] = chars
	return ["Title", "UI_Label", cfg]


## **可折叠段**（片段构造器）：一个 UI_Panel，标题常显、内容写成 `items` **展开才建**（见 fold / _build_items）。
## "一条一段"的列表全用它——各一览（见 UI_View._section）、UI 编辑器（每个键 / 子UI一段）。
## 于是"段长什么样"只有一处，谁也不必再抄一遍 `size / collapsed / items / title_item` 那四行。
## `name_` 是这一段的元素名（同一父级下要唯一；重名会自动加后缀，见 UIBase._unique_child_name）。
## `chars` 同 `title_item`：>0 就给标题限宽（"标题最多/最少多宽"，见那儿的说明）。
static func section_item(name_: String, title: String, items: Array, folded: bool = true,
		chars: int = 0) -> Array:
	return [name_, "UI_Panel", {
		"size": [0, 0],
		"collapsed": folded,
		"items": items,
		"children": [title_item(title, folded, chars)],
	}]


## 折叠那条绑定**就在 QName 里**（`QName.UI_event_pointer1_fold_parent`：按下 ⇒ 收起/展开所在分组
## ＋ 两套文字对调 ＋ 刷新）——常用绑定都放那儿，改也只改一处。这里只是把它拼成 meta 的形状。
## 注意指令里**别出现 `]`**（如路径写 `arr[0]`）：BBCode 的 `[url=…]` 读到 `]` 就完了。
static var LINK_FOLD := UIInteract_Meta.as_meta(QName.UI_event_pointer1_fold_parent)

## 箭头上的说明文字（**两套**，跟箭头本身一样随状态换）：展开时提示"点它收起"、收起时提示"点它展开"。
const TIP_OPEN := "收起"
const TIP_SHUT := "展开"


## 标题的两套文字（`[现在显示的, 对调后的]`）：收起 = `▸ …`、展开 = `▾ …`。
## **箭头本身是 `[url]` 链接**，它的 meta 挂**两条**（一段链接可以挂多条，一行一条，见 UIInteract_Meta）：
##   `Pointer 1 Hold:` ⇒ 折叠（见 `LINK_FOLD`）
##   `Pointer Move:`  ⇒ 弹说明浮窗（内容见 TIP_*，开的是 "Tip" 预设）
## 于是"点它收起 / 点它展开"这句提示**跟着状态换**：两套文字本来就是整段对调的，链接的 meta 也就换了。
## 被谁用：`title_item`（建的时候）、以及"**就地改标题文字**"的调用方——
## 技能一览每物理帧都要把"最近执行"换一遍（重铺整段扛不住那个频率），改的时候**两套要一起改**
## （config 里的 `content` / `content_2`），不然下一次点收起 / 展开对调时会换出旧文字。
static func title_texts(title: String, collapsed: bool = false) -> Array:
	var shut: String = "[url=%s]▸[/url] %s" % [_sym_meta(TIP_SHUT), title]
	var open_: String = "[url=%s]▾[/url] %s" % [_sym_meta(TIP_OPEN), title]
	return [shut, open_] if collapsed else [open_, shut]


## 箭头那段链接的 meta：折叠（`LINK_FOLD`）＋ 悬停说明（开 "Tip" 预设，内容随状态给）。
## 两条之间用**换行**分隔——`\v` 是"一条指令里接多条子指令"，两种分隔各管一段，别混用（见 UIInteract_Meta）。
static func _sym_meta(tip: String) -> String:
	var hover: String = UIInteract_Meta.as_meta([
		QName.pointer_move,
		'UIInteract.open(@self, "Tip", @self, content="%s")' % tip])
	return LINK_FOLD + "\n" + hover


## 点"可折叠标题"由配置里的 `meta_event` + 箭头链接的 meta 承担（见 `title_item` / `LINK_FOLD`）：
## 折在箭头上就折叠、落在别处就拖动，**各有各的指令**。


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
