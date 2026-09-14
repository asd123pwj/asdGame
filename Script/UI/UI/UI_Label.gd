class_name UI_Label
extends UIBase
## 文本元素：content 即显示文本。
## 可兼任"按钮"或"拖动手柄"——配置事件→指令（如 UIInteract.close $parent / drag $parent）即可，
## 显示与交互解耦，无需单独的 Button 类。

## 内层文本控件（本元素的 control）。
## 被谁用：refresh（刷文本）。
var label: Label


## 建控件：本元素的外观就是一个 Label。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	label = Label.new()
	label.name = name
	return label


## 把 content 刷成文本；content 为空则显示空串。
## 被谁用：UIBase.build() 末尾、UIBase.set_content。
func refresh() -> void:
	label.text = str(content) if content != null else ""
