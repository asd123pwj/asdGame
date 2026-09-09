class_name UI_HPBar
extends UIBase
## 血条自定义元素（type 名 = "HPBar"，去 UI_ 前缀）。
## 生成一个 ProgressBar（最小原型用原生条）；后续按文档扩展自定义绘制/绑定刷新。


func build(ctx: Dictionary, desc: Dictionary) -> Array:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 20)
	if desc.has("name"):
		bar.name = desc["name"]

	# 从描述或 ctx 的 style 设置尺寸/颜色（先做尺寸）
	var style: Dictionary = {}
	if ctx.has("parent_style"):
		var ps: Variant = ctx["parent_style"]
		if ps is Dictionary:
			style = ps
	if desc.has("style") and desc["style"] is Dictionary:
		var s: Dictionary = desc["style"]
		for k in s:
			style[k] = s[k]
	if style.has("size") and style["size"] is Array:
		var a: Array = style["size"]
		if a.size() >= 2:
			bar.custom_minimum_size = Vector2(float(a[0]), float(a[1]))

	# 上/满值：最小原型给默认 0..100，之后由绑定刷新接管
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 50.0

	# ctx 里可挂一个刷新回调占位，后续接绑定系统
	if ctx.has("bind_hook") and ctx["bind_hook"] is Callable:
		var hook: Callable = ctx["bind_hook"]
		hook.call(bar, desc.get("bind", ""), ctx)
	return [true, bar]
