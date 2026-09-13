class_name UI_Label
extends UIBase
## 文本元素：content 即显示文本。
## 可兼任"按钮"或"拖动手柄"——配置 press/move 指令（如 UIInteract.drag $parent）即可，
## 显示与交互解耦，无需单独的 Button 类。

var label: Label


func _create_control() -> Control:
	label = Label.new()
	label.name = name
	return label


func refresh() -> void:
	label.text = str(content) if content != null else ""
