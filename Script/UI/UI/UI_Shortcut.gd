class_name UI_Shortcut
extends UI_View
## **角色快捷监控 / 编辑**：把某个角色装着的**系统快捷**（`Character.shortcuts`）逐条摆出来：
## 一条一段，**段标题 = 名称 + 依赖状态**（收起时也看得出这条绑在什么上），
## 展开才见两个输入框：**依赖的状态名（可改）/ 要执行的指令（可改）**——就是快捷预设的两个字段
## （见 SystemShortcutPreset：`dependence_status`、`config`）。
##
## **看哪个角色 / 铺 / 只重铺一段 / 记住展开态**这套骨架都在 `UI_View`（一条一段与其它五个一览同构，
## 原来那种"常显块"已收进这一种段）。本元素只回答它那组钩子，另加两个"写回预设"的方法。
##
## **改了什么、谁跟着变**（这是本元素与"快捷预设"的接口，别绕过它直接改字段）：
##   · **指令**：写回预设的 `config`。触发时是**现读**（`SystemShortcutPreset.listen` 的闭包里读 `config`），
##     所以改完立刻生效，**不用重听**。
##   · **依赖状态**：写回预设的 `dependence_status` 后**必须重新监听**（旧的那条 `listen_status_satisfied` 还挂着，
##     不换就等于"写了个没人看的字段"）——`_relisten()` 做这件事：先 `unlisten(char_)` 再 `listen(char_)`。
##   · 两者改完都**只重铺那一段**（`UI_View._refresh_section`，位置与展开态都不动），于是输入框里的值也跟上。
## **注意预设是全项目共享的**（一个快捷名一份，见 SystemShortcutPreset._we）：改它 = 改**所有**装了这条快捷的角色，
## 不只是眼前这个。这是"改预设"不是"改角色身上的某个实例"（角色身上只有"装没装"）。
##
## **指令里的多条命令**：预设里用 `\v` 分隔（见 CmdSys）。输入框里**显示成换行**、提交时再换回 `\v`
## （编辑期间回车是"提交"、插不进换行，所以换行只可能来自原来那几处 ⇒ 往返无损）。
##
## **不做实时**：清单是原型里声明的（装到角色身上就固定），而"快捷加 / 减"的消息**按快捷名分节点**
## （`listen_shortcut_add(角色, 名字)`），没有"任意快捷"这种通配订阅 ⇒ 加删之后点 `[刷新]`。
## **也不显示"依赖状态现在满不满足"**：那是状态一览（UI_Status）的活儿，摆两份就是同一件事两套策略。


## ---------- 铺什么（UI_View 那组钩子）----------
func _head_title() -> String:
	return "系统快捷"


func _missing_text() -> String:
	return "" if _all() != null else "这个角色还没有快捷集合"


## **那张表**：一条快捷一个条目。
func _keys() -> Array:
	var names_: Array = _all().shortcuts.keys()
	names_.sort()
	return names_


func _count_text(n: int) -> String:
	return "共 %d 条快捷（点标题展开改 依赖状态 / 指令；改的是**预设**，所有装它的角色都受影响）" % n


## 段标题：名称 + 依赖状态（收起时也看得出这条绑在什么上）。
func _title_of(key: String) -> String:
	var preset: SystemShortcutPreset = _preset(key)
	return key if preset == null else "%s ｜ 依赖：%s" % [key, str(preset.dependence_status)]


## 段里的行：两个标签 + 两个输入框（名称已在标题上）。
## **标签与输入框同宽**（都取本视图的 `_chars()`）：输入框原来写死 340px，而标签没有上限 ⇒
## 文字标签比输入框宽出一截、看着像"框太窄、换行换得莫名其妙"（实测踩过）。现在都按字符数走。
func _rows_of(key: String) -> Array:
	var preset: SystemShortcutPreset = _preset(key)
	if preset == null:
		return []
	return [
		_row("SL", "    依赖状态（回车提交；改了会重新监听）", Color(0.33, 0.39, 0.50)),
		["SI", "UI_Input", _input_cfg(key, "status", preset.dependence_status, 2,
			"@self.parent.parent.write_status(@self.config.scut, @self.control.text)")],
		_row("CL", "    执行的指令（多条命令在预设里用 \\v 分隔，这里显示成换行）", Color(0.33, 0.39, 0.50)),
		["CI", "UI_Input", _input_cfg(key, "cmd", _input_text(preset.config), 4,
			"@self.parent.parent.write_cmd(@self.config.scut, @self.control.text)")],
	]


## ---------- 改：依赖状态 / 指令 ----------
## 提交"依赖状态"（输入框回车调它）：写回预设 → **重新监听** → 重铺这一条。
## 为什么必须重听：`listen` 是按**当时那个状态名**订的消息；只改字段的话新状态满足时不会触发。
## 被谁用：状态输入框的提交指令（`@self.parent.parent.write_status(@self.config.scut, @self.control.text)`）。
func write_status(shortcut_name: String, text: String) -> void:
	var preset: SystemShortcutPreset = _preset(shortcut_name)
	if preset == null:
		return
	var want: String = text.strip_edges()
	if want == "":
		push_warning("UI_Shortcut: 「%s」的依赖状态不能为空（清空会变成一条永远不触发的快捷），已忽略" % shortcut_name)
		return
	if want == preset.dependence_status:
		return
	preset.dependence_status = want
	_relisten(preset)
	_refresh_section(shortcut_name)


## 提交"指令"（输入框回车调它）：写回预设的 `config`（**不用重听**：触发时现读），重铺这一条。
## 输入框里显示的是"换行版"（见 _input_text），这里换回 `\v` 分隔（CmdSys 的写法）。
func write_cmd(shortcut_name: String, text: String) -> void:
	var preset: SystemShortcutPreset = _preset(shortcut_name)
	if preset == null:
		return
	var want: String = text.replace("\r", "").replace("\n", '\v')
	if want == preset.config:
		return
	preset.config = want
	_refresh_section(shortcut_name)


## 重新监听某个预设（换依赖状态之后）：先退掉旧的，再按新字段听一遍。
## 只对"这个角色身上装着它"的情况动手（没装过就什么都不做，避免给无关角色挂监听）。
func _relisten(preset: SystemShortcutPreset) -> void:
	var char_: Character = shown_char()
	if char_ == null or char_.shortcuts == null or not char_.shortcuts.check_exist(preset.name):
		return
	if preset._trigger_funcs.has(char_):
		preset.unlisten(char_)
	preset.listen(char_)


## ---------- 取数据 ----------
## 这个角色的快捷集合（没有就给 null，`_missing_text` 靠它说话）。
func _all() -> SystemShortcuts:
	var char_: Character = shown_char()
	return char_.shortcuts if char_ != null else null


## 这个角色身上装着的那条预设（编辑只动"它身上装的"；没装就返回 null）。
func _preset(shortcut_name: String) -> SystemShortcutPreset:
	var all: SystemShortcuts = _all()
	return all.shortcuts.get(shortcut_name) if all != null else null


## 输入框的配置：值放 `content`，`scut` 记"是哪条快捷"（提交指令用它），
## 事件两条：点进编辑 + 回车提交（**先退出编辑再写**——写会重铺这一段、把输入框换掉，
## 不然 `InputSys.edit_ui` 会指着已经没了的框）。
## `rows` 是**最多显示几行**（`max_lines`）：框高 = 行数 × 行高 + 上下内边距，而**行高是量出来的**
## （见 UIBase._row_height）⇒ 换字体、换字号都不用来改这里的数。少了行就会冒竖滚动条，看着像"卡住了"。
## 宽度取本视图的 `_chars()`（`max_chars`，字符数）——**不写像素宽**：换了字体，字符宽自己跟着变；
## 更要紧的是与本段的标签同宽（见 `_rows_of`）。
func _input_cfg(shortcut_name: String, which: String, text: String, rows: int, submit: String) -> Dictionary:
	return {
		"multiline": true,                 # 命令可能长；多行 + 自动换行 + 最多显示行数（见 UI_Input）
		"max_lines": rows,
		"max_chars": _chars(),             # 宽度按字符数；高那维不写 = 随内容（上限是 max_lines）
		"content": text,
		"scut": shortcut_name,
		"which": which,
		"events": [
			QName.UI_event_pointer1_edit,
			[QName.input_submit, "UIInteract.end_edit(@self)" + '\v' + submit],
		],
	}


## 指令串 → 输入框里显示的文字：`\v`（多条命令的分隔）显示成换行，看着才像"好几条"。
## 提交时再换回 `\v`（见 write_cmd）——编辑期间回车是提交、插不进换行，所以换行只可能来自这里，往返无损。
static func _input_text(cmd: String) -> String:
	return cmd.replace('\v', "\n")
