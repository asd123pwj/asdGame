class_name UIInteract_Edit
extends UIInteractBase
## UI 交互：**开始 / 结束编辑输入**（`UIInteract.begin_edit` / `UIInteract.end_edit`）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。
##
## **编辑这件事整个在交互层**：输入框元素（UI_Input）只保留"把 content 刷进框里"这一件事，
## 抢焦点、置编辑状态、退出编辑都在这里 —— 它们是"UI 交互"这一层的活，不是元素自身的数据。
##
## 为什么要是命令：编辑的**时机**是用法，而且一律由配置写，元素里没有任何特判：
##   · "点输入框就进编辑"就是一条普通事件：`[QName.pointer1_hold, 'UIInteract.begin_edit self']`
##     （换成别的事件触发也行——元素不认键位）；
##   · "开某个菜单后直接开始打字""提交之后要不要退出编辑"同样写在配置里：
##       'UIInteract.open(@self, "Editor（内容对象）", @self, close_on_move=true)\vUIInteract.begin_edit(输入框)'
##       'Utils.write("…config.content", @self.control.text)\vUIInteract.end_edit(@self)'
##     （搜索框那种"提交完继续打字"就不写最后那条。）
## 点别处的自动退出不在这里：那是 PointerDetect.key 开头顺手收掉的（每次点击派发前都会先结束编辑）。


## 让目标开始编辑：抢焦点 + 置 InputSys 的编辑状态（编辑期间按键不进状态层，见 InputSystem._input）。
## 指令写法：UIInteract.begin_edit self
static func begin_edit(target: UIBase) -> void:
	var ui := _as_ui(target, "begin_edit")
	if ui == null or ui.control == null:
		return
	if not (ui.control is LineEdit or ui.control is TextEdit):
		push_warning("UIInteract.begin_edit: 「%s」的控件不是输入框（%s），没法编辑"
			% [ui.name, ui.control.get_class()])
		return
	# **已经在编辑这一个了 ⇒ 不再抢焦点**（这条指令挂在 HOLD 上：按住期间**每帧都会来一次**，
	# 见文件头"用 HOLD 不用 PRESS"那条；每帧抢一次焦点会顺手重置光标闪烁 / IME 之类，没必要）。
	var already: bool = InputSys.edit_ui == ui
	# 置编辑目标 + 发"正在编辑"那条状态消息**在 InputSys 里成对做**（见 InputSys.begin_edit）：
	# 于是"编辑中要不要屏蔽某个键 / 回车算不算提交"都能写成状态，输入层不必自己特判。
	InputSys.begin_edit(ui)
	if already:
		return
	ui.control.grab_focus()
	# **不要"进来就全选"**（以前这里按控件类型调 select_all）：这条指令是逐帧的，
	# 全选只会在**第一帧**起作用——人按不出"只按一帧"，等于没有；而它每帧再执行一次的话，
	# 用户按住拖动选字时选区每帧都被清成全选（"拖不动、只能全选"实测就是这么来的）。
	# 要全选用系统那套：三击 / Ctrl+A（输入框自带，那几个键走"归输入框自己"那条路）。


## 让目标结束编辑：清掉 InputSys 的编辑状态并放掉控件焦点（"谁在编辑"是 InputSys 的状态）。
## 指令写法：UIInteract.end_edit self
static func end_edit(target: UIBase) -> void:
	var ui := _as_ui(target, "end_edit")
	if ui == null:
		return
	if InputSys.edit_ui != null and InputSys.edit_ui != ui:
		push_warning("UIInteract.end_edit: 正在编辑的是「%s」，不是「%s」（还是要收掉编辑）"
			% [InputSys.edit_ui.name, ui.name])
	# 清编辑 + 发"没在编辑了"也成对在 InputSys 里（见 InputSys.end_edit）：
	# 这样"点别处"那条路收掉编辑时，状态层同样会收到（以前只有这条命令发，于是状态停在"编辑中"）。
	InputSys.end_edit()
