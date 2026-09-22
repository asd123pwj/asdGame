class_name UI_Input
extends UIBase
## 输入框元素（单行 LineEdit / 多行 TextEdit）：content 是**配置里写的初值**（refresh 时写进框里，
## 正在编辑时不回写），回车提交 → 派发事件 QName.input_submit（编辑期间由 InputSystem._input 翻译，
## 单行 / 多行一致）。
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
##   · 高度按"**换行后的视觉行数**"自动算（见 _content_size），再用 `config["max_height"]` 封顶
##     （超了就框内滚动，不会一个内容把界面顶长）；**宽度由容器给**（放在带 scroll 的面板里会撑满视口）；
##   · **回车仍然是提交**（不是换行）：命令串里要的是 `\v` 分隔、不是 `\n`，所以换行只作为**显示**；
##     InputSystem 会把编辑中的回车翻成 QName.input_submit **并吃掉事件**，不让 TextEdit 插进换行。
## 高度只在 build / refresh 时算：**不连 text_changed 信号**（全项目不连引擎信号，见 UI.md），
## 所以正在打字时框高不动（提交、或重建菜单之后跟上）。
##
## 编辑状态记在 InputSys（`edit_ui`）：`UIInteract_Edit.begin_edit` 抢焦点并置上它；
## 结束走 `UIInteract.end_edit` 命令，或者"点别处"（PointerDetect.key 开头先把编辑收掉）。
## 事件本身走的还是项目自己的链（配置里的 mouseLeft + 需要时冒泡给父级）。


## 多行模式的高度补白（上下内边距，TextEdit 自己不算进行高里）。
const MULTILINE_PAD: float = 10.0


func _create_control() -> Control:
	if bool(config.get("multiline", false)):
		var te: TextEdit = TextEdit.new()
		te.name = name
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY   # 自动换行（长内容一眼看全）
		te.scroll_fit_content_height = false             # 高度由本元素按行数算（有上限，见 _content_size）
		# 折了几行要**知道宽度**才知道，而建的时候宽度还没定（容器还没排）⇒ 等布局给宽再重算一次。
		# 用引擎信号是不得已：这个信息只有控件自己知道（同 UI_Panel 挂 minimum_size_changed 的理由）。
		# resized 只在尺寸真的变了才发 ⇒ 重算里再设一次尺寸不会来回抖。
		te.resized.connect(_reheight)
		return te
	var line: LineEdit = LineEdit.new()
	line.name = name
	return line


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


## 多行模式的内容尺寸：高度按"**换行后的视觉行数**"算，并按 config["max_height"] 封顶（超了框内滚动）；
## 宽度仍问控件自己（实际宽度由容器给——放在带 scroll 的面板里会撑满视口）。
## **算在这里而不是直接设 custom_minimum_size**：_fit_size 会用本函数的结果合成控件尺寸，
## 直接设会被它覆盖掉（那是"配置想要多大 ↔ 内容需要多大"的合成点）。
## 被谁用：UIBase._fit_size（build 与 refresh 都会走到）。
func _content_size() -> Vector2:
	if not (control is TextEdit):
		return super._content_size()
	var te: TextEdit = control
	var visual: int = 0
	for i in te.get_line_count():
		visual += 1 + te.get_line_wrap_count(i)      # 逻辑行 + 它折出来的行
	var h: float = float(maxi(visual, 1)) * float(te.get_line_height()) + MULTILINE_PAD
	var max_h: float = float(config.get("max_height", 0))
	if max_h > 0.0:
		h = minf(h, max_h)
	return Vector2(te.get_combined_minimum_size().x, h)
