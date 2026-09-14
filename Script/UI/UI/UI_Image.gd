class_name UI_Image
extends UIBase
## 图片元素：content 即纹理路径，refresh() 时加载并贴上；改图 = set_content(新路径)。
## 与其它元素同一条输入链路（PointerDetect 命中 → 事件 → 指令），可按需配 press/move 指令。

## 内层贴图控件（本元素的 control）。
## 被谁用：refresh（换纹理）。
var image: TextureRect


## 建控件：TextureRect（按 size 拉伸填充）。
## 被谁用：UIBase.build()。
func _create_control() -> Control:
	image = TextureRect.new()
	image.name = name
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	return image


## 把 content 当纹理路径加载；空则清空贴图（load 有缓存，重复路径不重复读盘）。
## 被谁用：UIBase.build() 末尾、UIBase.set_content。
func refresh() -> void:
	if content == null or str(content) == "":
		image.texture = null
		return
	image.texture = load(str(content))
