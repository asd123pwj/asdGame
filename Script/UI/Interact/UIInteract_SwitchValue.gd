class_name UIInteract_SwitchValue
extends UIInteractBase
## UI 交互：**开关列表里的某一项**（`UIInteract.switch_value`）——"有就删、没有就加"。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## 在 target 的 config[key] 列表里开关一个值：列表里**已经有（按内容比）就删掉，没有就追加**。
## 与 `Utils.swap`（对调两条路径）的分工：
##   Utils.swap   对调两套配置（两套都写死在元素上，整份换）——适合"开关式按钮"连行为带文案一起换；
##   switch_value 只加减**一项**——适合"给宿主加/减一条绑定"（如菜单里的"启用拖拽"），
##                不必为此在宿主预设里预先摆两套 events 并手工保持同步。
## 为什么改完就生效：config 是"数据"，`events` 这类列表在派发时（UIBase.on_event）才读；
## 但 content 这种要刷到控件上的键不在本函数职责内（改完在配置里接一条 `@self.refresh("content")`）。
## 值怎么给：指令里可以直接引变量，如 `QName.UI_event_mouseLeft_drag`
##   （见 Config/QuickName.gd：`[QName.mouseLeft, "UIInteract.drag self event"]`）——
##   常用的那条绑定只写一处，配置里填空即可。
## 被谁用：Config/UI/UIPreset_Menu.gd 的 EnableDrag（给宿主加/减"按住拖动"）。
static func switch_value(target: UIBase, key: String, value: Variant) -> void:
	var ui := _as_ui(target, "switch_value")
	if ui == null:
		return 
	var raw: Variant = ui.config.get(key)
	if raw == null and not ui.config.has(key):
		# 键名写错（如 "event" ↔ "events"）最典型：照旧按"新建列表"处理，但要说一声——
		# 否则指令写错了什么反应都没有，只能靠猜
		push_warning("UIInteract.switch_value: config 里没有 \"%s\" 这个键（写错了吗？按新建列表处理）" % key)
	if raw != null and not (raw is Array):
		push_warning("UIInteract.switch_value: config[\"%s\"] 不是列表（是 %s），不切换"
			% [key, type_string(typeof(raw))])
		return
	var list: Array = raw if raw != null else []
	# 按内容找（数组比数组走 ==，所以"同一条绑定"认得出来，不必比引用）
	var idx: int = list.find(value)
	if idx >= 0:
		list.remove_at(idx)
	else:
		list.append(value)
	ui.config[key] = list
