class_name UIInteract_Content
extends UIInteractBase
## UI 交互：**改显示内容**（`UIInteract.set_content`）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## 修改目标 UI 的显示内容（内部 set_content → refresh），如更新滚动区文本。
## 被谁用：预设里 "UIInteract.set_content $parent \"新文本\""；
## 外部改内容一般直接 get_ui(...).set_content(...)（见 Test.ui_test）。
static func set_content(target: UIBase, content: Variant) -> void:
	var ui := _as_ui(target, "set_content")
	if ui == null:
		return
	ui.set_content(content)
