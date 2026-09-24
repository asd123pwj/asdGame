class_name UI_Label
extends UIBase
## 文本元素（**内核是 RichTextLabel**；元素名保留 UI_Label，既有配置一字不改）：
## content 即文本，**按 BBCode 解析** ⇒ `[b]` / `[color]` / `[url=…]` 都能用。
## "段落里哪几个字可以点 / 可以悬浮"由此变成引擎原生能力：`[url=meta]文字[/url]`——
## meta 怎么写见 `UIInteract_Meta`（形状是 `事件名:指令`，如 `Pointer 1 Hold:UIInteract.drag(@host, @event)`）；
## 本元素只负责把引擎"指针在哪段链接上"的信号记进 `meta_hover`（**点击也读它**：点在链接上时它就是那段）。
## **链接不画下划线**（`underline_alpha` 置 0，见 reapply）；悬停在 [url] 上指针自动变手型。
## （以前这里是普通 Label，"段落里的可点词"只能手搓逐字命中，已删——引擎有现成的，别再造。）
##
## **尺寸**：
##   · `size` 高度写 0 ⇒ `fit_content`（高随内容、不出滚动条）；
##   · 高度写了数 ⇒ 显示区**定死**（fit_content 关），内容多了**框内滚动**——
##     "三行文本只显示两行"就是这么配的（测滚动条）。
##   · `max_chars` / `max_width` 是宽度上限 ⇒ **宽 = min(内容自然宽, 上限)**：短内容不撑满、
##     超了才折行（见 `_content_size`；RichTextLabel 本来就自动换行，**折行后的 meta 命中依旧跟手**）；
##     不配就交给容器。
## 字体走 `normal_font` / `normal_font_size` / `default_color`（RichTextLabel 的主题项名与 Label 不同，
## 见 reapply）。

## 内层文本控件（本元素的 control；**RichTextLabel**）。
## 被谁用：refresh（刷文本）、_refit。
var label: RichTextLabel

## **正在悬停的那段 `[url]` 的 meta**（没有 = null）：由引擎信号维护（见 _create_control）。
## 点击时读它就是"点到了哪个链接"——**链接之外它一定是 null** ⇒ 不会把上一次的交互"粘"到空文本上
## （用 `meta_clicked` 就会：它只在点到链接时更新，点空白文本不刷新，实测就出了这个 bug）。
## 被谁用：UIInteract_Meta（meta_event）、UIInteract_Fold（折叠箭头那段链接的 meta）。
var meta_hover: Variant = null


## 建控件：BBCode 开着；默认"高随内容、无滚动条"，`size` 高度写死才切成"定高 + 框内滚动"。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	label = RichTextLabel.new()
	label.name = name
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	if _config_size().y > 0.0:                     # 高度写死 = 显示区定死：内容多了框内滚动
		label.fit_content = false
		label.scroll_active = true
	# 内容高度取决于它拿到的宽（自动换行）⇒ 宽变了把元素尺寸重算一遍
	# （连几帧等它排完版，同 UI_Input._reheight 的理由；它自己会发 minimum_size_changed，这里只是跟）。
	label.resized.connect(_refit)
	# meta 的命中**只有控件自己知道**（这个版本的 RichTextLabel 没有"查指针下 meta"的方法，
	# 只有两个 hover 信号）⇒ 按"不得已才连引擎信号"的既有先例接进来（同 minimum_size_changed / resized）：
	# 记进 meta_hover 供指令读。**点击不另接信号**：点的时候"指针正悬停的那段"就是被点的那段。
	label.meta_hover_started.connect(_on_meta_hover)
	label.meta_hover_ended.connect(_on_meta_hover_end)
	return label


func _on_meta_hover(meta: Variant) -> void:
	meta_hover = meta


func _on_meta_hover_end(_meta: Variant) -> void:
	meta_hover = null


## 字体 / 字号 / 字色：RichTextLabel 的主题项名与 Label 不同，基类写的那几条它读不到 ⇒ 这里补正确的。
## （同样只有一个入口：字体来自 SysCfg.ui_font_file，见 UISystem.apply_default_font。）
## 被谁用：UIBase.reapply（build 与"改完配置让界面跟上"都走它）。
func reapply() -> void:
	super.reapply()
	if not (control is RichTextLabel):
		return
	var rtl: RichTextLabel = control
	if UISys.ui_font != null:
		# normal 之外，[b] / [i] / [code] 各有自己的槽：同族没有 Bold ⇒ 都指到同一个字体文件
		for item in ["normal_font", "bold_font", "italics_font", "mono_font"]:
			rtl.add_theme_font_override(item, UISys.ui_font)
	var font_size: int = maxi(int(config.get("font_size", SysCfg.ui_font_size_default)),
		SysCfg.ui_font_size_default)
	for item in ["normal_font_size", "bold_font_size", "italics_font_size", "mono_font_size"]:
		rtl.add_theme_font_size_override(item, font_size)
	if config.has("font_color"):
		rtl.add_theme_color_override("default_color", config["font_color"])
	# **链接不画下划线**：`[url]` 默认带一条下划线（标题里的 ▾ 箭头、拖动文字上都不好看）。
	# 这个版本里链接没有单独的"链接色"主题项（颜色项只有 default_color / selection 那几个），
	# 下划线是**常量 `underline_alpha`** 管的 ⇒ 0 = 看不见（`[u]` 也一并没了；本项目不用 `[u]`）。
	# 想留一点就配 `"underline_alpha"`（主题常量是整数，按引擎的量纲给）。
	rtl.add_theme_constant_override("underline_alpha", int(config.get("underline_alpha", 0)))


## 内容尺寸。**宽度是这三档**（高度都是"引擎按这个宽报的内容高"）：
##   · 配了上限（`max_chars` / `max_width`）⇒ **宽 = min(内容自然宽, 上限)**：
##     短内容就按内容那么宽（"关闭"两个字的说明不该撑出一大段空白），长了才到上限并折行；
##   · 没配、但容器已经给了宽 ⇒ 就用这个宽（别自己另报一个）；
##   · 没配、宽还没定（刚建出来）⇒ **先按一行报**，等容器给宽后 `resized` → `_refit` 再算。
## 为什么后两档不能照抄引擎报的尺寸：那时控件宽是 1px（还没排），RichTextLabel 会按"一个字一行"
## 报出 1×N 行的最小尺寸，而 `_fit_size` 会把它固定成元素尺寸 ⇒ **一行文字变成一列高塔**
## （实测：快捷名 "Key J" 变 1×120，五个元素之间因此空出一大段）。
## 被谁用：UIBase._fit_size。
## 宽度听容器的两种情况（见 `_in_fixed_panel` 与 `wrap`）：见 `_content_size` / UIBase._fit_size。
func _width_from_parent() -> bool:
	return bool(config.get("wrap", false)) or _in_fixed_panel()


func _content_size() -> Vector2:
	# **读控件"自身"的最小尺寸（get_minimum_size），不读 combined**：combined 会把我们上一轮写进
	# custom_minimum_size 的旧值也算进来 ⇒ 一旦某帧因为"宽还没定"报高了，这个高就永远粘住
	# （实测：快捷名 "Key J" 卡在 1×120 五行高，怎么刷新都不掉）。
	var need: Vector2 = control.get_minimum_size()
	# **宽度听容器**（见 `_width_from_parent`）⇒ 报 0：不去撑容器，宽度由容器给；
	# 高度按**给到的那点宽**折行算（宽一变 resized → _refit 再算）。
	# 这是"面板尺寸定、内容跟着面板走"的那一半；反过来（内容为准）走下面的分支。
	if _width_from_parent():
		return Vector2(0.0, need.y)
	var cap: float = _max_width_px(control)
	if cap > 0.0:
		return Vector2(minf(_plain_width(control), cap), need.y)
	if control.size.x > 0.0:
		return Vector2(control.size.x, need.y)
	return Vector2(need.x, _row_height(control))


## 这段文字**不折行**时的自然宽度（像素）：去掉 BBCode 后按行量，取最宽的那行（再留 1px 余量）。
## **为什么要自己量**：RichTextLabel 报的"内容宽"是**按它当前宽度折行后**最宽那一行的宽——
## 宽还没定、或已经折行了，都问不出"本来有多宽"，于是"短内容也撑满上限"或"被压成一列"。
## 只算普通字宽（不区分 `[b]` 等），对本项目的文案足够。
## 被谁用：_content_size（有宽度上限那一档）。
func _plain_width(ctrl: Control) -> float:
	var rtl: RichTextLabel = ctrl
	var font: Font = rtl.get_theme_font("normal_font")
	var fs: int = rtl.get_theme_font_size("normal_font_size")
	var best: float = 0.0
	for line in rtl.get_parsed_text().split("\n"):
		best = maxf(best, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var sb: StyleBox = rtl.get_theme_stylebox("normal")
	return best + sb.content_margin_left + sb.content_margin_right + 1.0


## 元素尺寸跟着内容高重算（宽变 ⇒ 折行变 ⇒ 高变）：连几帧等排版稳定（有界，见 _create_control）。
## 被谁用：RichTextLabel 的 resized 信号。
func _refit(round_: int = 2) -> void:
	if control == null:
		return
	_fit_size()
	if round_ > 0:
		Callable(self, "_refit").bind(round_ - 1).call_deferred()


## 把 config["content"] 刷成文本（BBCode 原样进 RichTextLabel.text）。
## 被谁用：UIBase.build() 末尾、配置里改完 content 紧跟的 `@self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	var v: Variant = config.get("content")
	label.text = str(v) if v != null else ""
