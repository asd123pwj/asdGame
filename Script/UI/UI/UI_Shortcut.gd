class_name UI_Shortcut
extends UI_View
## **角色快捷监控 / 编辑**：把某个角色装着的**系统快捷**（`Character.shortcuts`）逐条摆出来：
## **名称（只读）/ 依赖的状态名（可改）/ 要执行的指令（可改）**——后两样就是快捷预设的字段
## （见 SystemShortcutPreset：`dependence_status`、`config`）。
##
## **看哪个角色 / 铺的骨架在 `UI_View`**（查看项 `content_cmd` 优先、其次 config 的 `char`；推迟一帧铺、
## 换对象自动重铺）。本元素只实现 `_fill`（每条快捷一块）——**不做实时**（理由见下）。
##
## **改了什么、谁跟着变**（这是本元素与"快捷预设"的接口，别绕过它直接改字段）：
##   · **指令**：写回预设的 `config`。触发时是**现读**（`SystemShortcutPreset.listen` 的闭包里读 `config`），
##     所以改完立刻生效，**不用重听**。
##   · **依赖状态**：写回预设的 `dependence_status` 后**必须重新监听**（旧的那条 `listen_status_satisfied` 还挂着，
##     不换就等于"写了个没人看的字段"）——`_relisten()` 做这件事：先 `unlisten(char_)` 再 `listen(char_)`。
##   · 两者都**重铺那一条**（`UIBase.replace_child_element`，位置不动），于是输入框里的值也跟上。
## **注意预设是全项目共享的**（一个快捷名一份，见 SystemShortcutPreset._we）：改它 = 改**所有**装了这条快捷的角色，
## 不只是眼前这个。这是"改预设"不是"改角色身上的某个实例"（角色身上只有"装没装"）。
##
## **指令里的多条命令**：预设里用 `\v` 分隔（见 CmdSys）。输入框里**显示成换行**、提交时再换回 `\v`
## （编辑期间回车是"提交"、插不进换行，所以换行只可能来自原来那几处 ⇒ 往返无损）。
##
## **不做实时**：清单是原型里声明的（装到角色身上就固定），而"快捷加 / 减"的消息**按快捷名分节点**
## （`listen_shortcut_add(角色, 名字)`），没有"任意快捷"这种通配订阅 ⇒ 加删之后点 `[刷新]`。
## **也不显示"依赖状态现在满不满足"**：那是状态一览（UI_Status）的活儿，摆两份就是同一件事两套策略。

## 每条快捷那一块：快捷名 -> 块（UI_Panel）。改完只重铺这一块（位置不动）。
var _blocks: Dictionary = {}


## 清掉"快捷名 → 块"的索引（重铺时由 UI_View.reload 调）。
func _before_fill() -> void:
	_blocks.clear()


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
	_redo_block(shortcut_name)


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
	_redo_block(shortcut_name)


## 重新监听某个预设（换依赖状态之后）：先退掉旧的，再按新字段听一遍。
## 只对"这个角色身上装着它"的情况动手（没装过就什么都不做，避免给无关角色挂监听）。
func _relisten(preset: SystemShortcutPreset) -> void:
	var char_: Character = shown_char()
	if char_ == null or char_.shortcuts == null or not char_.shortcuts.check_exist(preset.name):
		return
	if preset._trigger_funcs.has(char_):
		preset.unlisten(char_)
	preset.listen(char_)


## 重铺一条快捷（老的块原地换掉，位置不动——同 UI_Status：摘掉再加会跳到最底下）。
func _redo_block(shortcut_name: String) -> void:
	var char_: Character = shown_char()
	if char_ == null or char_.shortcuts == null:
		return
	var preset: SystemShortcutPreset = char_.shortcuts.shortcuts.get(shortcut_name)
	if preset == null:
		return
	_block(preset, _blocks.get(shortcut_name))


## 这个角色身上装着的那条预设（编辑只动"它身上装的"，没装就返回 null）。
func _preset(shortcut_name: String) -> SystemShortcutPreset:
	var char_: Character = shown_char()
	if char_ == null or char_.shortcuts == null:
		return null
	return char_.shortcuts.shortcuts.get(shortcut_name)


## ---------- 铺 ----------
## 铺：抬头 → 取不到角色就说清怎么给 → 每条快捷一块（名称常显 + 两个输入框）。
func _fill() -> void:
	_fill_head("系统快捷")
	if _fill_missing():
		return
	var char_: Character = shown_char()
	if char_.shortcuts == null:
		add_child_element("NoSet", "UI_Label", {"content": "这个角色还没有快捷集合"})
		return
	var dict: Dictionary = char_.shortcuts.shortcuts
	var names_: Array = dict.keys()
	names_.sort()
	add_child_element("Count", "UI_Label", {
		"content": "共 %d 条快捷（名称只读；状态 / 指令改完回车提交；改的是**预设**，所有装它的角色都受影响）" % names_.size(),
		"font_color": Color(0.55, 0.60, 0.70),
	})
	for shortcut_name in names_:
		_block(dict[shortcut_name])


## 一条快捷 = 一块（一个 UI_Panel，含 5 个子元素）：名称 / "依赖状态"标签 + 输入框 / "执行的指令"标签 + 输入框。
## 包成一块是为了**能原地换**（改完只重铺这一块，见 _redo_block）；输入框的提交指令从自己往上数两级到本元素
## （输入框 → 块 → 本元素），所以写回方法挂在本元素上。
## **标签与输入框同宽**（都取本视图的 `_chars()`）：输入框原来写死 340px，而标签没有上限 ⇒
## 文字标签比输入框宽出一截、看着像"框太窄、换行换得莫名其妙"（实测踩过）。现在都按字符数走。
## `old` 给了 ⇒ 原地换掉它（位置不动）；否则追加。
func _block(shortcut: SystemShortcutPreset, old: UIBase = null) -> void:
	var key: String = str(shortcut.name)
	var cfg: Dictionary = {
		"size": [0, 0],
		"children": [
			["N_" + key, "UI_Label", {
				"content": key,
				"font_color": Color(0.85, 0.88, 0.95),
			}],
			["SL_" + key, "UI_Label", {
				"content": "    依赖状态（回车提交；改了会重新监听）",
				"font_color": Color(0.62, 0.68, 0.78),
				"max_chars": _chars(),
			}],
			["SI_" + key, "UI_Input", _input_cfg(key, "status", shortcut.dependence_status, 2, _chars(),
				"@self.parent.parent.write_status(@self.config.scut, @self.control.text)")],
			["CL_" + key, "UI_Label", {
				"content": "    执行的指令（多条命令在预设里用 \\v 分隔，这里显示成换行）",
				"font_color": Color(0.62, 0.68, 0.78),
				"max_chars": _chars(),
			}],
			["CI_" + key, "UI_Input", _input_cfg(key, "cmd", _input_text(shortcut.config), 4, _chars(),
				"@self.parent.parent.write_cmd(@self.config.scut, @self.control.text)")],
		],
	}
	var name_: String = "B_" + key
	var block: UIBase = replace_child_element(old, name_, "UI_Panel", cfg) if old != null \
		else add_child_element(name_, "UI_Panel", cfg)
	_blocks[key] = block


## 输入框的配置：值放 `content`，`scut` 记"是哪条快捷"（提交指令用它），
## 事件两条：点进编辑 + 回车提交（**先退出编辑再写**——写会重铺这一块、把输入框换掉，
## 不然 `InputSys.edit_ui` 会指着已经没了的框）。
## `rows` 是**最多显示几行**（`max_lines`）：框高 = 行数 × 行高 + 上下内边距，而**行高是量出来的**
## （见 UIBase._row_height）⇒ 换字体、换字号都不用来改这里的数。少了行就会冒竖滚动条，看着像"卡住了"。
## `chars` 是**宽度**（`max_chars`，字符数）——**不写像素宽**：换了字体，字符宽自己跟着变；
## 更要紧的是与本块的标签同宽（见 _block 的说明）。
static func _input_cfg(shortcut_name: String, which: String, text: String, rows: int, chars: int,
		submit: String) -> Dictionary:
	return {
		"multiline": true,                 # 命令可能长；多行 + 自动换行 + 最多显示行数（见 UI_Input）
		"max_lines": rows,
		"max_chars": chars,                # 宽度按字符数；高那维不写 = 随内容（上限是 max_lines）
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


## 看的是哪个角色 / 按路径取角色：都走 `UI_View`（`shown_path()` / `shown_char()`）——
## 三个一览共用那一份，别在这儿再写一份。

