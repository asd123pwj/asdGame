class_name UI_Image
extends UIBase
## 图片元素：content 即纹理路径，refresh() 时加载并贴上；改图 = set_content(新路径)。
## 与其它元素同一条输入链路（PointDetect 命中 → 事件 → 指令），可按需配 press/move 指令。

var image: TextureRect


func _create_control() -> Control:
	image = TextureRect.new()
	image.name = name
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	return image


func refresh() -> void:
	if content == null or str(content) == "":
		image.texture = null
		return
	# content 视为纹理资源路径；已在缓存的 load 直接复用
	image.texture = load(str(content))
