class_name UiSystem
extends BaseClass
## UI 管理脚本（设计见 Script/UI/UI.md）。
## 只负责 UI 的生命周期：按 UIPreset 挂载/移除整棵 UI 树（含子元素登记）。
## 交互（关闭/拖动/渐隐/改内容）在 UIInteract 静态类，元素按事件发指令驱动。

var root: CanvasLayer
var uis: Dictionary[String, UIBase] = {}


func _init() -> void:
	root = CanvasLayer.new()
	root.name = "UIRoot"
	# 初始化发生在 Sys._ready()（引擎仍在建子节点），需延迟到本帧空闲再挂载
	Sys.sys.get_tree().root.add_child.call_deferred(root)


func add_ui(name: String) -> Enums.Code:
	if uis.has(name):
		return Enums.Code.NOT_MODIFIED
	var preset: UIPreset = UIPreset.get_(name)
	if preset == null or preset.ui == null:
		return Enums.Code.NOT_FOUND
	var ctrl: Control = preset.ui.build()
	root.add_child(ctrl)
	_register_tree(preset.ui, name)
	Msg.send_ui_create(preset.ui)
	return Enums.Code.OK


func remove_ui(name: String) -> Enums.Code:
	if not uis.has(name):
		return Enums.Code.NOT_MODIFIED
	var ui: UIBase = uis[name]
	var keys: Array[String] = []
	_collect_tree(ui, name, keys)
	for key in keys:
		uis.erase(key)
	if ui.control != null:
		ui.control.queue_free()  # 子元素 control 都挂在根控件下，随之一并释放
	Msg.send_ui_remove(ui)
	return Enums.Code.OK


func get_ui(name: String) -> UIBase:
	return uis.get(name)


func check_ui(name: String) -> bool:
	return uis.has(name)


## 登记整棵 UI 树：根用原名，子元素用 "根名/子名"。
## 子元素也进 uis，PointerDetect 才能把指针命中派发到具体子元素（如关闭按钮）。
func _register_tree(ui: UIBase, full_name: String) -> void:
	uis[full_name] = ui
	for child in ui.children:
		_register_tree(child, full_name + "/" + child.name)


## 收集整棵树的登记名。
func _collect_tree(ui: UIBase, full_name: String, out_keys: Array[String]) -> void:
	out_keys.append(full_name)
	for child in ui.children:
		_collect_tree(child, full_name + "/" + child.name, out_keys)
