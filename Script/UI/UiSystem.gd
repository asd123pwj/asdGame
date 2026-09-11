class_name UiSystem
extends BaseClass
## UI 管理脚本（设计见 Script/UI/UI.md）。
## 持 UI 根(CanvasLayer)，按 UIPreset 挂载/移除 UI，持有当前全部 UI 集合，操作时发 Msg。

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
	uis[name] = preset.ui
	Msg.send_ui_create(preset.ui)
	return Enums.Code.OK


func remove_ui(name: String) -> Enums.Code:
	if not uis.has(name):
		return Enums.Code.NOT_MODIFIED
	var ui: UIBase = uis[name]
	if ui.control != null:
		ui.control.queue_free()
	uis.erase(name)
	Msg.send_ui_remove(ui)
	return Enums.Code.OK


func get_ui(name: String) -> UIBase:
	return uis.get(name)


func check_ui(name: String) -> bool:
	return uis.has(name)
