class_name UI_Panel
extends UIBase
## 面板容器：自身只是外观 + 竖排布局，功能（标题/关闭按钮/滚动内容…）
## 全部由 config["children"] 声明的子元素组装（见 Script/UI/UI.md）。

var _box: VBoxContainer


func _create_control() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = name

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	_box = VBoxContainer.new()
	margin.add_child(_box)
	return panel


## 子元素挂到内部竖排容器。
func _content_box() -> Control:
	return _box
