class_name UI_Label
extends UIBase
## 文本元素：content 即显示文本。
## 可兼任"按钮"或"拖动手柄"——配置事件→指令（如 UIInteract.close @self.parent / drag @self.parent）即可，
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


## 把 config["content"] 刷成文本；没写 / 为 null 则显示空串。
## 被谁用：UIBase.build() 末尾、配置里改完 content 紧跟的 `@self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	var v: Variant = config.get("content")
	label.text = str(v) if v != null else ""
