class_name PointerDetect
extends BaseClass
## 指针目标检测（设计见 Script/Input/Input.md）。
## 根据 InputSys.mouse_position 计算指针下的目标：hover_ui / hover_char / map_position。
## 本类**只提供执行函数，不监听按键**：按键→状态→SystemShortcut→执行指令的链路
## 由 Character 的 Status 与 SystemShortcut 声明（状态满足即执行对应 CmdSys 指令）。
##
## **事件派发只有一个入口 `key(status_name)`**：不区分 press/hold/release/move，也不碰键位——
## 键位只存在于状态层（statuses 的 keys），这里只管"哪个状态满足了"，把它当事件名派发给 UI。
## 参数由快捷指令串给出（如 `PointerDetect.key "Mouse Left"`），因此
## "增删/改绑多功能键"只需改配置，不必动本文件。
## 指针移动**不锁定目标**：每次移动都派发给当前 hover 的 UI，由它 config 里配的指令决定做什么。

## 指针当前目标
## 被谁用：key（事件派发给谁）、UiSys.close_blur_ui（失焦判定入参）。
static var hover_ui: UIBase = null
## 指针当前目标角色（占位功能，暂无人使用）。
static var hover_char: Character = null
## 指针当前目标地图格（占位功能，暂无人使用）。
static var map_position: Vector2i = Vector2i.ZERO
## 上次的 hover_ui，用于判 hover 变化并发 enter/exit
## 被谁用：update_targets。
static var _prev_hover_ui: UIBase = null

## hover 变化的两个内置事件名：它们不是配置里的状态（由 update_targets 判定后直接派发），
## UI 侧在 config["events"] 里用这两个常量绑同名的项即可。
## 被谁用：update_targets（派发）、Config/UI 里绑 "Pointer Enter/Exit" 的项。
const EVENT_POINTER_ENTER: String = "Pointer Enter"
const EVENT_POINTER_EXIT: String = "Pointer Exit"


func _init() -> void:
	pass


## 刷新指针下的目标；hover_ui 变化时对新旧目标发 enter/exit。
## 由 Tick 状态 → 快捷指令 `PointerDetect.update_targets` 每帧驱动
## （hover 展开子菜单依赖它，所以这里会每帧被调用）。
## 被谁用：Tick 状态的快捷指令；以及 key() 里"派发完按键后补刷一次"。
static func update_targets() -> void:
	hover_ui = _ui_at(InputSys.mouse_position)
	hover_char = _char_at()
	map_position = _map_at()
	if hover_ui != _prev_hover_ui:
		# hover 变化不对应任何状态，直接用上面两个内置事件名派发
		if _prev_hover_ui != null:
			_prev_hover_ui.on_event(EVENT_POINTER_EXIT)
		if hover_ui != null:
			hover_ui.on_event(EVENT_POINTER_ENTER)
		_prev_hover_ui = hover_ui


## 状态满足后的统一派发入口：把状态名当事件名派发给当前 hover 的 UI，
## UI 侧按状态名等值匹配 config["events"] 里的指令。
## 不区分 press/hold/release/move，也不涉及键位——"哪个状态满足了"已由状态层判定。
## 命中刷新由每帧的 `PointerDetect.update_targets`（Tick 状态驱动）负责，这里不重复刷新。
## 指针移动不锁定任何 UI —— 被拖的元素跟随光标，hover 始终是它。
## 被谁用：状态层 shortcuts 里的 `PointerDetect.key "<状态名>"`（见 Config/Character/Archetype）。
static func key(status_name: String) -> void:
	if hover_ui != null:
		hover_ui.on_event(status_name)
	# 按键后清理：配了 close_on_blur 的 UI（菜单就是这种，没有任何专属类），指针不在它上面就关掉。
	# 先刷新一次命中：这类 UI 常是刚在这一帧打开、或挪到了指针处，用旧的 hover 会误判成"在外面"。
	if UiSys.has_blur_ui():
		update_targets()
		UiSys.close_blur_ui(hover_ui)


## 指针命中的 UI（按加入顺序取最上层）。
## 用 is_visible_in_tree：父 UI 关闭(hide)后子元素也应视为不可命中。
## 注意 Rect2 退化（宽或高为 0）时永远命不中——UI 的 size 必须补足（见 UIBase._fit_size）。
## 被谁用：update_targets。
static func _ui_at(pos: Vector2) -> UIBase:
	var list: Array = UiSys.uis.values()
	for i in range(list.size() - 1, -1, -1):
		var ui: UIBase = list[i]
		if ui.control != null and ui.control.is_visible_in_tree() and ui.control.get_global_rect().has_point(pos):
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
## 取角色碰撞体矩形尺寸（body 下第一个矩形 CollisionShape2D）。
static func _body_size(body: CharacterBody2D) -> Vector2:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			return (child.shape as RectangleShape2D).size
	return Vector2.ZERO
