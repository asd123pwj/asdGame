class_name UIInteract_Edit
extends UIInteractBase
## UI 交互：**开始 / 结束编辑输入**（`UIInteract.begin_edit` / `UIInteract.end_edit`）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。
##
## **编辑这件事整个在交互层**：输入框元素（UI_Input）只保留"把 content 刷进框里"这一件事，
## 抢焦点、置编辑状态、退出编辑都在这里 —— 它们是"UI 交互"这一层的活，不是元素自身的数据。
##
## 为什么要是命令：编辑的**时机**是用法，而且一律由配置写，元素里没有任何特判：
##   · "点输入框就进编辑"就是一条普通事件：`[QName.mouseLeft, 'UIInteract.begin_edit $self']`
##     （换成别的事件触发也行——元素不认键位）；
##   · "开某个菜单后直接开始打字""提交之后要不要退出编辑"同样写在配置里：
##       "UIInteract.open $self MenuBind $self --close_on_move\vUIInteract.begin_edit $输入框"
##       'Utils.write "…config.content" $self.control.text\vUIInteract.end_edit $self'
##     （搜索框那种"提交完继续打字"就不写最后那条。）
## 点别处的自动退出不在这里：那是 PointerDetect.key 开头顺手收掉的（每次点击派发前都会先结束编辑）。


## 让目标开始编辑：抢焦点 + 置 InputSys 的编辑状态（编辑期间按键不进状态层，见 InputSystem._input）。
## 指令写法：UIInteract.begin_edit $self
static func begin_edit(target: UIBase) -> void:
	var ui := _as_ui(target, "begin_edit")
	if ui == null or ui.control == null:
		return
	if not (ui.control is LineEdit):
		push_warning("UIInteract.begin_edit: 「%s」的控件不是输入框（%s），没法编辑"
			% [ui.name, ui.control.get_class()])
		return
	InputSys.edit_ui = ui
	var line: LineEdit = ui.control
	line.grab_focus()
	line.select_all()               # 进来就全选：直接打就是替换


## 让目标结束编辑：清掉 InputSys 的编辑状态并放掉控件焦点（"谁在编辑"是 InputSys 的状态）。
## 指令写法：UIInteract.end_edit $self
static func end_edit(target: UIBase) -> void:
	var ui := _as_ui(target, "end_edit")
	if ui == null:
		return
	if InputSys.edit_ui != null and InputSys.edit_ui != ui:
		push_warning("UIInteract.end_edit: 正在编辑的是「%s」，不是「%s」（还是要收掉编辑）"
			% [InputSys.edit_ui.name, ui.name])
	InputSys.end_edit()
