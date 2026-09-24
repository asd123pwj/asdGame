class_name UI_Scroll
extends UIBase
## 滚动容器：content 即展示的内容（多行文本），refresh() 时刷新内层 Label。
## 修改展示 = 写本元素的 config["content"]（`Utils.write "<路径>.config.content" 新内容`），界面由 refresh 跟上。
## 注意 ScrollContainer 默认最小尺寸为 0：配置里必须给 size（可视区大小），否则不可见。
##
## 结构（与 UI_Panel 同一套，内部节点都起了名）：
##   root(Control，本元素的 control) → Scroll(ScrollContainer) → Label
##                                   └→ Overlay(Control)：free 子元素的自由定位挂载点
## **Overlay 必须挂在 root 上、不能在 ScrollContainer 里**：滚动容器会裁剪子节点、还会按自己的
## 视口改子节点尺寸 ⇒ 挂在里面的菜单既显示不全（被裁掉一块），尺寸又被压成 0——
## 而失焦判定里有一条"尺寸为 0 先跳过"（防布局还没跑），于是那种菜单**永远关不掉**。
## 所以"这个元素能不能装 free 子元素"取决于它的 control 是不是容器，而不是取决于它叫什么名字。

## 内层滚动容器。
## 被谁用：_create_control（建）、_apply_config（算内层文本宽度）、_content_box、_content_size。
var scroll: ScrollContainer
## 内层文本（挂在 scroll 下）。
## 被谁用：refresh（刷文本）、_apply_config（限宽以便换行）。
var label: Label
## free 子元素的挂载点（非容器、且不在滚动容器里：位置尺寸不被布局改，也不会被裁）。
## 被谁用：_create_control（建）、_free_box。
var _overlay: Control


## 建控件树：外层普通 Control（position/size 由配置决定）+ 全铺的滚动容器 + 自动换行的 Label + 叠加层。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	var root: Control = Control.new()
	root.name = name

	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(scroll)

	label = Label.new()
	label.name = "Label"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(label)

	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_overlay)
	return root


## 把 config["content"] 刷成文本（多行文本直接写，\n 换行）。
## 被谁用：UIBase.build() 末尾、配置里改完 content 紧跟的 `@self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	var v: Variant = config.get("content")
	label.text = str(v) if v != null else ""


## 普通子元素挂到滚动容器里（进滚动区，随滚动条走）。
## 被谁用：UIBase._build_children / add_child_element。
func _content_box() -> Control:
	return scroll


## 自由定位的子元素挂到**叠加层**（不在滚动容器里——见文件头：不然会被裁 + 尺寸被压成 0）。
## 被谁用：UIBase._build_children / add_child_element（free 分支）。
func _free_box() -> Control:
	return _overlay


## 叠加层公布给"往上找挂载点"的子孙元素（见 UIBase._free_box）。
func _own_free_layer() -> Control:
	return _overlay


## 内容最小尺寸要问滚动容器：根是普通 Control，不会汇总子元素的最小尺寸，
## 直接问它只会得到配置里写的那点值（理由同 UI_Panel._content_size）。
## 被谁用：UIBase._fit_size。
func _content_size() -> Vector2:
	return scroll.get_combined_minimum_size()


## 除公共属性外，再让内层文本宽度略小于滚动容器（留出滚动条），使长文本换行、超高可竖向滚动。
## 被谁用：UIBase.build()（先 super() 定好控件尺寸，这里才能算宽度）。
func _apply_config() -> void:
	super()
	label.custom_minimum_size.x = maxf(control.custom_minimum_size.x - 16.0, 40.0)


## 把 config["background"] 的图做成九宫格，套在**滚动容器**的 "panel" 槽上
## （根控件是普通 Control，自己不画 StyleBox，套在它身上什么也看不见——理由同 UI_Panel）。
## 被谁用：UIBase._apply_config。
func _apply_background(path: String) -> void:
	var style: StyleBoxTexture = _make_background(path)
	if style == null:
		return
	scroll.add_theme_stylebox_override("panel", style)
