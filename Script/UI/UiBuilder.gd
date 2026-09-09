class_name UiBuilder
extends BaseClass
## 把 UI 描述 Dictionary 解析成 Godot Control 树（文档见 Script/UI/UI设计.md §6/§9）。
## 最小原型范围：原生 type + children 递归 + style(显示属性) + text/cmd。
## 扩展位：自定义 UI_ 元素、ref 引用、extends 继承留待后续按文档补充。


# 原生 type -> Godot Control 类名。生成时 new 一个该类的实例。
static var _NATIVE_TYPES: Dictionary = {
	"Label": "Label",
	"Button": "Button",
	"Panel": "PanelContainer",
	"VBox": "VBoxContainer",
	"HBox": "HBoxContainer",
	"Grid": "GridContainer",
	"Scroll": "ScrollContainer",
	"ProgressBar": "ProgressBar",
}


# 构建一棵 UI。ui_desc: values 里一个完整 UI 描述（含 root/style）。
# ctx: { parent_style: Dictionary, track: Variant, ui_sys: Object } 等运行时上下文。
# 返回 [ok, root_control]
static func build(ui_desc: Dictionary, ctx: Dictionary = {}) -> Array:
	if not ui_desc.has("root"):
		return [false, null]
	var inherited: Dictionary = {}
	if ui_desc.has("style"):
		inherited = ui_desc["style"]
	var inner_ctx: Dictionary = ctx.duplicate()
	inner_ctx["parent_style"] = inherited
	return _build_node(ui_desc["root"], inner_ctx)


static func _build_node(desc: Dictionary, ctx: Dictionary) -> Array:
	var node_type: String = desc.get("type", "")

	# 自定义元素（UI_ 前缀类）优先于原生兜底
	if _NATIVE_TYPES.has(node_type):
		var cls: String = _NATIVE_TYPES[node_type]
		var node: Control = ClassDB.instantiate(cls)
		if node == null:
			return [false, null]
		return _finalize_node(node, node_type, desc, ctx)

	# type 是自定义元素：找 class_name == "UI_" + node_type 的元素类
	var custom: GDScript = _find_element_class(node_type)
	if custom != null:
		var builder_obj: Object = custom.new()
		if builder_obj is UIBase:
			var builder: UIBase = builder_obj
			var r: Array = builder.build(ctx, desc)
			if r[0]:
				return [true, r[1]]
	return [false, null]


# 原生节点收尾：设名字/文案/点击/样式 + 递归 children。
static func _finalize_node(node: Control, _node_type: String, desc: Dictionary, ctx: Dictionary) -> Array:
	var name_: String = desc.get("name", "")
	if not name_.is_empty():
		node.name = name_

	_apply_text(node, desc)
	_apply_command(node, desc)

	var style: Dictionary = _merge_style(ctx.get("parent_style", {}), desc.get("style", {}))
	_apply_style(node, style)

	if desc.has("children") and desc["children"] is Array:
		var child_ctx: Dictionary = ctx.duplicate()
		child_ctx["parent_style"] = style
		for ch_raw in desc["children"]:
			var ch: Dictionary = ch_raw
			var r: Array = _build_node(ch, child_ctx)
			if r[0]:
				node.add_child(r[1])
	return [true, node]


# 懒缓存：type -> 自定义元素脚本（class_name = "UI_" + type 且继承 UIBase）
static var _element_cache: Dictionary = {}

static func _find_element_class(node_type: String) -> GDScript:
	if _element_cache.has(node_type):
		return _element_cache[node_type]
	var target: String = "UI_" + node_type
	var found: GDScript = null
	for cls in ProjectSettings.get_global_class_list():
		if cls["class"] == target:
			var script: GDScript = load(cls["path"])
			# 校验继承 UIBase（其基类链里含 UIBase）
			if script != null and _extends_ui_base(script):
				found = script
			break
	_element_cache[node_type] = found
	return found


static func _extends_ui_base(script: GDScript) -> bool:
	var s: Script = script
	while s != null:
		if s.resource_path.get_file().get_basename() == "UIBase":
			return true
		s = s.get_base_script()
	return false


# 合并两层 style，self_style 优先覆盖 parent_style。
static func _merge_style(parent_style: Variant, self_style: Variant) -> Dictionary:
	var out: Dictionary = {}
	var p: Dictionary = parent_style if parent_style is Dictionary else {}
	var s: Dictionary = self_style if self_style is Dictionary else {}
	for k in p:
		out[k] = p[k]
	for k in s:
		out[k] = s[k]
	return out


# 把合并后的 style 应用到 Control 节点（最小原型支持的常用显示属性）。
static func _apply_style(node: Control, style: Dictionary) -> void:
	if style.has("position") and style["position"] is Array:
		var p: Vector2 = _vec2(style["position"])
		node.position = p
	if style.has("size") and style["size"] is Array:
		var s: Vector2 = _vec2(style["size"])
		node.custom_minimum_size = s
	if style.has("visible"):
		node.visible = bool(style["visible"])
	if node is Label and style.has("font_size"):
		node.add_theme_font_size_override("font_size", int(style["font_size"]))
	if node is Label and style.has("color"):
		node.add_theme_color_override("font_color", _color(style["color"]))
	if node is Button and style.has("font_size"):
		node.add_theme_font_size_override("font_size", int(style["font_size"]))


static func _vec2(a: Array) -> Vector2:
	if a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


static func _color(c: Variant) -> Color:
	if c is String:
		var cs: String = c
		if cs.begins_with("#"):
			return Color(cs)
	if c is Array:
		var arr: Array = c
		if arr.size() >= 3:
			return Color(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]) if arr.size() > 3 else 1.0)
	return Color.WHITE


static func _apply_text(node: Control, desc: Dictionary) -> void:
	if not desc.has("text"):
		return
	if node is Label:
		var label: Label = node
		label.text = str(desc["text"])
	elif node is Button:
		var button: Button = node
		button.text = str(desc["text"])


static func _apply_command(node: Control, desc: Dictionary) -> void:
	# 最小原型：Button 点击后发命令（经 Msg 门面）。cmd 可能是字符串或命令数组。
	if not (node is Button) or not desc.has("cmd"):
		return
	var cmd: Variant = desc["cmd"]
	var btn: Button = node
	if cmd is String:
		btn.pressed.connect(func():
			Msg.send_cmd(str(cmd))
		)
	elif cmd is Array:
		btn.pressed.connect(func():
			for c in cmd:
				Msg.send_cmd(str(c))
		)
