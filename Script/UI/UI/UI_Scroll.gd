class_name UI_Scroll
extends UIBase
## 滚动容器：content 即展示的内容（多行文本），refresh() 时刷新内层 Label。
## 修改展示 = 对本元素 set_content(新内容)，无需重建控件。
## 注意 ScrollContainer 默认最小尺寸为 0：配置里必须给 size（可视区大小），否则不可见。

## 内层滚动容器（本元素的 control）。
## 被谁用：_create_control（建）、_apply_config（算内层文本宽度）。
var scroll: ScrollContainer
## 内层文本（挂在 scroll 下）。
## 被谁用：refresh（刷文本）、_apply_config（限宽以便换行）。
var label: Label


## 建控件：ScrollContainer + 自动换行的 Label。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	scroll = ScrollContainer.new()
	scroll.name = name
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(label)
	return scroll


## 把 content 刷成文本（多行用 \n 连接）。
## 被谁用：UIBase.build() 末尾、UIBase.set_content。
func refresh() -> void:
	label.text = str(content) if content != null else ""


## 除公共属性外，再让内层文本宽度略小于滚动容器（留出滚动条），使长文本换行、超高可竖向滚动。
## 被谁用：UIBase.build()（先 super() 定好控件尺寸，这里才能算宽度）。
func _apply_config() -> void:
	super()
	label.custom_minimum_size.x = maxf(control.custom_minimum_size.x - 16.0, 40.0)
