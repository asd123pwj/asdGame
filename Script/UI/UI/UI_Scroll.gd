class_name UI_Scroll
extends UIBase
## 滚动容器：content 即展示的内容（多行文本），refresh() 时刷新内层 Label。
## 修改展示 = 对本元素 set_content(新内容)，无需重建控件。

var scroll: ScrollContainer
var label: Label


func _create_control() -> Control:
	scroll = ScrollContainer.new()
	scroll.name = name
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(label)
	return scroll


func refresh() -> void:
	label.text = str(content) if content != null else ""


func _apply_config() -> void:
	super()
	# 内层文本宽度略小于滚动容器（留出滚动条），使长文本换行、超高可竖向滚动
	label.custom_minimum_size.x = maxf(control.custom_minimum_size.x - 16.0, 40.0)
