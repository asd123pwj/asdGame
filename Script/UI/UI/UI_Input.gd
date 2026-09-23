class_name UI_Input
extends UIBase
## 输入框元素（单行 LineEdit / 多行 TextEdit）：content 是**配置里写的初值**（refresh 时写进框里，
## 正在编辑时不回写）；**回车提交 → 派发事件 QName.input_submit**（编辑中按回车照常进状态链，
## `QName.submit` = 回车 ∧ 没按 Shift 满足时由状态侧派发，见 `Archetype_System` / `SystemManager`）。
## 本元素**不碰输入层**：`InputSystem` 拦"归输入框自己的键"（打字键 + 方向键 / 退格 / 删除 / Tab…，
## 见 `_is_input_only_key`），回车**照常进状态链**、但**提交状态满足时会把那个事件吃掉**（见 `_submit_now`）
## ⇒ 单回车不会在框里留下换行；按着 Shift 就不吃 ⇒ 多行框插一个换行（"Shift + 回车 = 换行"）。
##
## **元素自己没有任何特判**：不连引擎信号，也不写死"点我进编辑"——那只是一条普通事件配置，
## 用什么事件触发由写配置的人决定：
##   ["Name", "UI_Input", {
##       "size": [240, 0],
##       "events": [
##           [QName.mouseLeft, 'UIInteract.begin_edit(@self)'],        # 点它进编辑（换事件就改这一条）
##           [QName.input_submit,
##               # 送到绑定名指的那个 UI：绑定名记在**窗口**的 config 上，用 host 取（不必数级数）；
##               # 路径写成**带引号的字符串**（不然里面的 @注册名.config 会被当取值式解析）
##               'Utils.write(@self.config.send_to, @self.control.text)'
##               + '\vUtils.write("@self.config.content")'              # 不写值 = 清空框（content 置 null）
##               + '\vUIInteract.end_edit(@self)'                       # 先退出编辑（想"提交完继续打字"就不写这条）
##               + '\v@self.refresh("content")']],                          # 自己也是只改了 content
##           # **改了什么就刷什么**；顺序别反——编辑中的输入框会跳过刷新，先刷就把"清空"漏掉了
##       ],
##   }]
## 框里正在打的字**不往 content 同步**：要用就用取值链直接读 `@self.control.text`（见 UI.md）。
## "送到哪"由绑定名给出：`@host.config.content_cmd` 是**窗口**上记的那个名字（host = 沿 parent 爬到顶那个 UI）；
## 名字没设 / 对应 UI 不在登记表里时，整条路径写不进去，Utils.write 会警告一声（不静默）。
##
## **多行模式**（`config["multiline"] = true`，控件换成 TextEdit）——给"命令很长、一行看不全"的场合用：
##   · **自动换行**（长内容一眼看全，不用横向拖）；
##   · 高度 = **"换行后的视觉行数" × 行高 + 上下内边距**（见 _text_height），再用 `config["max_lines"]`
##     封顶（"最多显示几行"）：**超过就框内滚动**，竖滚动条自己出来，不会一个内容把界面顶长；
##   · **行高是量出来的**（字高 + 主题行距，见 _row_height）⇒ 换字体 / 换字号 / 换主题都自动跟着变，
##     配置里不写像素高度（`size` 的那一维写 0），也就不存在"换个字体就得手改数字"。
##   · **回车仍是提交、不会插换行**（Shift+回车才是换行）：输入层判"这次算提交"就把那个事件吃掉
##     （见 `InputSystem._submit_now`），TextEdit 拿不到它，自然插不进换行。
## **宽度上限**（两种模式都认）——给"放在宽面板里、不想被拉满"的场合，两种说法：
##   · `max_width`：**像素**；`max_chars`：**字符数**（**中文算 2**——默认字体是等宽文楷，
##     中文正好两个半角宽，见 `_half_width`）。两个都写取小的那个；
##   · 宽度 = **上限本身**（短内容也不缩——同一栏里的框要对齐；左右边距算进去），
##     **同时把横向填充关掉**（竖排容器默认"撑满"，不关上限等于没写）；
##   · 到上限之后：多行框**换行**（折出来的行数让框变高），单行框是 LineEdit，只会**横向滚**
##     （光标打到哪显示哪，它本身没有滚动条——要"换行看得全"就得用多行模式）；
##   · 上限是**硬上限**：连 `size` 里写的宽也压（`size` 是"想要的宽"，`max_*` 是"最大"）。
## 尺寸只在 build / refresh 时算：**不连 text_changed 信号**（全项目不连引擎信号，见 UI.md），
## 所以正在打字时框高不动（提交、或重建菜单之后跟上）。
##
## 编辑状态记在 InputSys（`edit_ui`）：`UIInteract_Edit.begin_edit` 抢焦点并置上它；
## 结束走 `UIInteract.end_edit` 命令，或者"点别处"（PointerDetect.key 开头先把编辑收掉）。
## 事件本身走的还是项目自己的链（配置里的 mouseLeft + 需要时冒泡给父级）。


func _create_control() -> Control:
	if bool(config.get("multiline", false)):
		var te: TextEdit = TextEdit.new()
		te.name = name
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY   # 自动换行（长内容一眼看全）
		te.scroll_fit_content_height = false             # 高度由本元素按行数算（有上限，见 _content_size）
		_apply_width_cap(te)
		# 折了几行要**知道宽度**才知道，而建的时候宽度还没定（容器还没排）⇒ 等布局给宽再重算一次。
		# 用引擎信号是不得已：这个信息只有控件自己知道（同 UI_Panel 挂 minimum_size_changed 的理由）。
		# resized 只在尺寸真的变了才发 ⇒ 重算里再设一次尺寸不会来回抖。
		te.resized.connect(_reheight)
		return te
	var line: LineEdit = LineEdit.new()
	line.name = name
	_apply_width_cap(line)
	return line


## 配了宽度上限就把横向填充关掉：竖排容器默认"撑满"，不关的话上限等于没写（容器照旧拉满）。
## 被谁用：_create_control（两种模式）。
func _apply_width_cap(ctrl: Control) -> void:
	if _max_width_px(ctrl) > 0.0:
		ctrl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


## 覆写：宽度上限是**硬上限**，连 `size` 里写的宽也压（"最大"就是最大：
## `size` 是"想要的宽"，`max_width` / `max_chars` 是"不许超过"）。
## 封在**"想要的宽"这一步**，而不是 `_fit_size` 之后再改控件尺寸——
## 后者会让"容器给的宽 ↔ 折行数"来回弹（尺寸一变就发 resized，`_reheight` 又去重算）。
## 被谁用：UIBase._fit_size。
func _config_size() -> Vector2:
	var want: Vector2 = super._config_size()
	var cap: float = _max_width_px(control)
	if cap > 0.0 and want.x > cap:
		want.x = cap
	return want


## 重算高度（多行模式）：**连着几帧各算一次**（默认 3 次，有界）。
## 为什么要连算几帧：折行数（get_line_wrap_count）要等控件拿到宽度、主题字体就绪并重排完才准，
## 建的那一帧读到的还是旧值——只算一次会停在"一行高"（实测）。
## 正在编辑时跳过（别在人家打字时跳）。
## 被谁用：TextEdit 的 resized 信号、refresh（内容换了）。
func _reheight(round_: int = 2) -> void:
	if control == null or control.has_focus():
		return
	_fit_size()
	if round_ > 0:
		Callable(self, "_reheight").bind(round_ - 1).call_deferred()


## config["content"] → 框里的文字（配置初值、或被写过的 content）。
## **正在编辑时不动**：框里的字还没进 content（不同步），这时候回写等于把人打的字冲掉。
## 被谁用：build() 末尾、配置里改完 content 紧跟的 `@self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	if control == null or control.has_focus():
		return                      # 正在编辑：别把人家打的字冲掉
	var v: Variant = config.get("content")
	var text: String = "" if v == null else str(v)
	if control is TextEdit:
		(control as TextEdit).text = text
	else:
		(control as LineEdit).text = text
	_reheight()                     # 多行模式：内容换了 ⇒ 折行数变了 ⇒ 高度重算（单行时是空转）


## 内容尺寸。单行：控件自己要的高度（宽度：有上限就是那宽，没有交给容器）。
## 多行：行数按"**换行后的视觉行数**"，再用 `config["max_lines"]`（最多显示几行）封顶；
##   高度 = 行数 × 行高 + 上下内边距（`_text_height`）。行数被截到上限之后，框比内容矮 ⇒
##   竖滚动条自己就出来了（这正是"最多显示 N 行"想要的效果）。
## **宽度：有上限（`max_width` / `max_chars`）就取上限那个宽**——短内容也不缩，
## 因为"一栏里的输入框"要对齐（同 UI_Label 的规则）；没上限就交给容器。
## **算在这里而不是直接设 custom_minimum_size**：_fit_size 会用本函数的结果合成控件尺寸，
## 直接设会被它覆盖掉（那是"配置想要多大 ↔ 内容需要多大"的合成点）。
## 被谁用：UIBase._fit_size（build 与 refresh 都会走到）。
func _content_size() -> Vector2:
	if not (control is TextEdit):
		return _cap_width(super._content_size())
	var te: TextEdit = control
	var rows: int = 0
	for i in te.get_line_count():
		rows += 1 + te.get_line_wrap_count(i)        # 逻辑行 + 它折出来的行
	var max_lines: int = int(config.get("max_lines", 0))     # 最多显示几行（0 = 不限）
	if max_lines > 0:
		rows = mini(rows, max_lines)
	var w: float = _max_width_px(te)                 # 有上限就是那宽（同栏对齐）；没上限才交给容器
	if w <= 0.0:
		w = te.get_combined_minimum_size().x
	return Vector2(w, _text_height(te, rows))


## 多行框"刚好装下 `rows` 行"要的高度：`rows × 行高 + 上下内边距`。
## **必须加上下内边距**：字画在 stylebox 的内容区里（主题给 `normal` 的 content_margin），
## 不算进去 = 内容比框高几像素 ⇒ **滚动条自己冒出来**（"刚好两行却有条"就是这么来的——
## 以前这里是个拍脑袋的常量 4，比真实边距小）。
## 被谁用：_content_size。
static func _text_height(te: TextEdit, rows: int) -> float:
	var sb: StyleBox = te.get_theme_stylebox("normal")
	return float(maxi(rows, 1)) * _row_height(te) + sb.content_margin_top + sb.content_margin_bottom


## 收宽度上限（0 = 不限）。到顶之后怎么显示由控件自己决定：
## 多行框换行（见 _content_size 把高的那一维重算）、单行框横向滚。
## 被谁用：_content_size（单行那一路；多行那一路直接把上限当宽度）。
func _cap_width(size_: Vector2) -> Vector2:
	var cap: float = _max_width_px(control)
	if cap > 0.0:
		size_.x = cap
	return size_
