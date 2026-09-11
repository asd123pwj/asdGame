class_name PointDetect
extends BaseClass
## 指针目标检测（设计见 Script/Input/Input.md）。
## 按需根据 InputSys.mouse_position 计算指针下的目标：hover_ui / hover_char / map_position。
## 本类**只提供执行函数，不监听按键**：按键→状态→SystemShortcut→执行指令的链路
## 由 Character 的 Status 与 SystemShortcut 声明（状态满足即执行对应 CmdSys 指令）。
## 因此这里的函数都是可被指令系统调用的静态方法（如 `PointDetect.pointer_down`）。

## 指针当前目标
static var hover_ui: UIBase = null
static var hover_char: Character = null
static var map_position: Vector2i = Vector2i.ZERO
## 正在拖动的 UI（按下时锁定，避免拖动中目标漂移）
static var dragging_ui: UIBase = null


func _init() -> void:
	pass


## 按需更新指针下的目标。
static func update_targets() -> void:
	hover_ui = _ui_at(InputSys.mouse_position)
	hover_char = _char_at()
	map_position = _map_at()


## 指针键按下：取回当前目标并派发；命中 UI 执行操作，其它暂忽略。
static func pointer_down() -> void:
	update_targets()
	if hover_ui == null:
		return
	dragging_ui = hover_ui
	dragging_ui.on_pointer_down()


## 指针键按住：拖动跟随（天然支持连按/长按）。
static func pointer_move() -> void:
	if dragging_ui == null:
		return
	update_targets()
	dragging_ui.on_pointer_move()


## 指针键抬起：结束拖动。
static func pointer_up() -> void:
	if dragging_ui == null:
		return
	dragging_ui.on_pointer_up()
	dragging_ui = null


## 提交键：对指针下的 UI 派发提交。
static func submit() -> void:
	update_targets()
	if hover_ui != null:
		hover_ui.on_submit()


## 指针命中的 UI（按加入顺序取最上层）。
static func _ui_at(pos: Vector2) -> UIBase:
	var list: Array = Sys.uiSys.uis.values()
	for i in range(list.size() - 1, -1, -1):
		var ui: UIBase = list[i]
		if ui.control != null and ui.control.visible and ui.control.get_global_rect().has_point(pos):
			return ui
	return null


## 我没说要实现这个，但它先帮我实现了，那就先占位用
## 指针命中的角色（按身体矩形判定）。
static func _char_at() -> Character:
	for char_: Character in Character._we.values():
		if char_.body == null:
			continue
		var size: Vector2 = _body_size(char_.body)
		if size == Vector2.ZERO:
			continue
		if Rect2(char_.body.global_position - size * 0.5, size).has_point(
				char_.body.get_global_mouse_position()):
			return char_
	return null


## 我没说要实现这个，但它先帮我实现了，那就先占位用
## 指针命中的地图格（逻辑坐标，y 向上为正）。
static func _map_at() -> Vector2i:
	var ts: Vector2 = TileSpritePreset.tileset.tile_size
	if ts.x <= 0.0 or ts.y <= 0.0:
		return Vector2i.ZERO
	var world: Vector2 = MapSys.maps_parent_node.get_global_mouse_position()
	return Vector2i(floori(world.x / ts.x), -floori(world.y / ts.y))


## 我没说要实现这个，但它先帮我实现了，那就先占位用
static func _body_size(body: CharacterBody2D) -> Vector2:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			return (child.shape as RectangleShape2D).size
	return Vector2.ZERO
