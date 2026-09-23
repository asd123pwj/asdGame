class_name UI_Label
extends UIBase
## 文本元素：content 即显示文本。
## 可兼任"按钮"或"拖动手柄"——配置事件→指令（如 UIInteract.close @self.parent / drag @self.parent）即可，
## 显示与交互解耦，无需单独的 Button 类。
##
## **给"一栏文字"定宽**（`max_width` 像素 / `max_chars` 字符数，与 UI_Input 同一套语义）：
##   配了就**自动开自动换行**（除非显式写了 `autowrap`），宽度**就等于上限**（短内容也不缩——同一栏要对齐），
##   高度按**折行后的实际行数**算。
##   **为什么"上限"必须连着"换行"**：Label 裁不了自己（没有 clip），不换行的长文字会直接溢出框、
##   比面板还宽——一览的段标题就是一行很长的小结，它没有上限，于是把面板撑到内容那栏的**两三倍宽**，
##   而内容那栏有上限、早早换了行，两边对不上（实测踩过）。所以在本元素里"上限"与"换行"是同一件事。
## **不配上限**：宽度 = 文字本身、高度 = 文字本身的高度（一行多高是量出来的，见 `_row_height`）。

## 内层文本控件（本元素的 control）。
## 被谁用：refresh（刷文本）、_reheight。
var label: Label


## 建控件：本元素的外观就是一个 Label。
## **文字竖直居中**：行高是"文字高度"（见 `_content_size`），配了更高的 `size` 时不居中会贴着上边；
## 对"高度 = 文字高"的元素这是空转。
## **自动换行**：配了宽度上限就自动开（见类说明）；要"没上限也要换行"就显式写 `"autowrap": true`，
## 那时宽度得由外面给（`size` 或容器）——不然它的最小宽只剩一个字，内容盒会缩成一条、
## 每个字独占一行（实测踩过，很难看）。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	label = Label.new()
	label.name = name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# **此刻 `control` 还没赋值**（build 里是 `control = _create_control()`）⇒ 上限要问**刚建的这个 label**，
	# 不能问 `self.control`——那是 null，会被判成"没配上限定"，于是既不换行也不改尺寸（实测踩过）。
	if _wrap_enabled(label):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# **别被容器拉满**：竖排容器默认"撑满"，拉满就比上限宽了（上限也就白配了）。
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		# 折了几行要等控件拿到宽度、字体主题就绪才准 ⇒ 等布局给宽再重算一次高度
		# （同 UI_Input._reheight 的理由；`resized` 只在尺寸真变了才发 ⇒ 收敛后不再抖）。
		label.resized.connect(_reheight)
	return label


## 要不要自动换行：显式配了 `autowrap` 听它的；否则**配了宽度上限就自动换**（见类说明）。
## `ctrl` 给了就用它（`_create_control` 里得这么调，那时 `control` 还是 null，见上）；
## 没给就用本元素的 `control`（refresh 那条路）。
func _wrap_enabled(ctrl: Control = null) -> bool:
	if config.has("autowrap"):
		return bool(config["autowrap"])
	return _max_width_px(ctrl if ctrl != null else control) > 0.0


## 内容尺寸：**有上限** ⇒ 宽 = 上限、高 = 折行数 × 行高（见 `_text_height`）；
## **没上限** ⇒ 控件自己要多大就多大（宽按文字、高按文字本身）。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	var cap: float = _max_width_px(control)
	if cap <= 0.0:
		return super._content_size()
	return Vector2(cap, _text_height(maxi(label.get_line_count(), 1)))


## 折行后"刚好装下 `rows` 行"的高度：**优先用引擎自己报的**（`get_minimum_size().y`）——
## 它按**当前宽度**折出来的行数算，含它自己的取整（实测 1/2/3 行 = 28/55/82，而
## `行数 × (字高 + 行距)` 给 27/54/81，差的就是那点取整）⇒ 用它的绝不会"比引擎要的少"。
## 引擎报 0（还没排版）或比公式还小才退回公式（那时 `get_line_count()` 也还不准，见 `_reheight`）。
## 被谁用：_content_size。
func _text_height(rows: int) -> float:
	var by_rows: float = float(maxi(rows, 1)) * _row_height(control)
	var engine: float = label.get_minimum_size().y
	return engine if engine >= by_rows else by_rows


## 重算尺寸（折行数变了才会变）：**连着几帧各算一次**（默认 2 次，有界）。
## 为什么要连算几帧：`get_line_count()` 要等控件拿到宽度、主题字体就绪并重排完才准
## （建的那一帧读到的还是旧值）；`resized` 会再触发一次，收敛之后自己就停了。
## 被谁用：Label 的 resized 信号、refresh（内容换了）。
func _reheight(round_: int = 2) -> void:
	if control == null or label == null:
		return
	_fit_size()
	if round_ > 0:
		Callable(self, "_reheight").bind(round_ - 1).call_deferred()


## 把 config["content"] 刷成文本；没写 / 为 null 则显示空串。
## 内容换了 ⇒ 折行数可能跟着变 ⇒ 尺寸重算（见 _reheight）。
## 被谁用：UIBase.build() 末尾、配置里改完 content 紧跟的 `@self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	var v: Variant = config.get("content")
	label.text = str(v) if v != null else ""
	if _wrap_enabled():
		_reheight()
