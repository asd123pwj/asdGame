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
## 被谁用：key（事件派发给谁）、UIInteract_OpenClose.close_blur_ui（失焦判定入参）。
static var hover_ui: UIBase = null
## 指针当前目标角色（占位功能，暂无人使用）。
static var hover_char: Character = null
## 指针当前目标地图格（占位功能，暂无人使用）。
static var map_position: Vector2i = Vector2i.ZERO
## 上次的 hover_ui，用于判 hover 变化并发 enter/exit
## 被谁用：update_targets。
static var _prev_hover_ui: UIBase = null

## hover 变化的两个内置事件名放在 QName 里（Config/QuickName.gd 的 pointer_enter / pointer_exit）：
## 它们不是配置里的状态，由 update_targets 判定后直接派发；
## UI 侧在 config["events"] 里绑这两个名字即可。
## 被谁用：update_targets（派发）。


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
			_prev_hover_ui.on_event(QName.pointer_exit)
		if hover_ui != null:
			hover_ui.on_event(QName.pointer_enter)
		_prev_hover_ui = hover_ui


## 状态满足后的统一派发入口：把状态名当事件名派发给当前 hover 的 UI，
## UI 侧按状态名等值匹配 config["events"] 里的指令。
## 不区分 press/hold/release/move，也不涉及键位——"哪个状态满足了"已由状态层判定。
## 命中刷新由每帧的 `PointerDetect.update_targets`（Tick 状态驱动）负责，这里不重复刷新。
## **"按住期间每帧要做的事"不走这里**：指针会离开元素（如等比缩放），那类交给 `AutoSys`
## （Script/Auto/Auto.md：挂在状态上，状态满足期间每帧执行指令，不满足自动删）——
## 所以不需要"把松开事件送到元素手上"这类捕获机制，指针层也不参与收尾。
## 被谁用：状态层 shortcuts 里的 `PointerDetect.key "<状态名>"`（见 Config/Character/Archetype）。
static func key(status_name: String) -> void:
	if hover_ui != null:
		hover_ui.on_event(status_name)
		# "点一下谁，谁在最上面"：除指针移动外的派发都算一次"点它"（HOLD 每帧都派发，
		# 由 set_top 内部去重，不会每帧重排）。移出判断是因为悬停不该改前后层。
		if not status_name in [QName.pointer_move, QName.pointer_enter, QName.pointer_exit]:
			UIInteract_SetTop.set_top(hover_ui)
	# 按键后清理：配了 close_on_blur 的 UI（菜单就是这种，没有任何专属类），指针不在它上面就关掉。
	# **必须先刷新一次命中**：这类 UI 常是刚在这次调用里打开的（右键开菜单），
	# 而 hover 是 Tick 每帧刷的（= 上一帧的指针位置）；不刷新就会拿旧 hover 判它 ⇒ 新菜单当场被关掉。
	update_targets()
	UIInteract_OpenClose.close_blur_ui(hover_ui)


## 指针命中的 UI —— **沿 Godot 的控件树走**（不再遍历登记表）：
##   从 UI 根的孩子（窗口）**倒序**开始，每一层也都倒序（同级里后画的在上面）；
##   进到一个 Control 里**先问它的孩子**（孩子画在父之上），孩子都不命中才算它自己。
## 于是**命中顺序 ≡ 绘制顺序**，`uis` 只是"名字 → 实例"的字典（顺序无含义），
## `set_top` 也只需 `move_to_front()`（旧版还要维护"登记顺序"，那套已删）。
## 反查 UIBase 用建控件时挂在 control 上的 meta（UIBase.build 里的 META_UI）：
## 走到没挂 meta 的内部控件（容器的 PanelContainer/VBox、文本内部的 Label）就沿用外层那个元素。
## **不做"祖先矩形剪枝"**：自由定位元素（叠加层里那些）本来就画在父矩形之外，菜单还会伸出宿主，
## 按父矩形剪掉子树 = 那些地方点不到（实测踩过：菜单被叠加层剪掉，点在菜单上却命中面板的文本）。
## 要"元素极多也快"得靠空间索引（按矩形分桶之类），不是这里剪一刀。
## 用 is_visible_in_tree：父 UI 关闭(hide)后子元素也应视为不可命中。
## 注意 Rect2 退化（宽或高为 0）时永远命不中——UI 的 size 必须补足（见 UIBase._fit_size）。
## 被谁用：update_targets。
static func _ui_at(pos: Vector2) -> UIBase:
	return _hit_in(UiSys.root, pos)


## 在 node 的孩子里倒着找命中的控件，命中则返回它对应的 UIBase（都没命中返回 null）。
## 被谁用：_ui_at（递归）。
static func _hit_in(node: Node, pos: Vector2) -> UIBase:
	for i in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(i)
		if not (child is Control):
			continue
		var c: Control = child
		if not c.is_visible_in_tree():
			continue
		var deeper: UIBase = _hit_in(c, pos)            # 孩子画在父之上，先问孩子
		if deeper != null:
			return deeper
		# 先 has_meta 再 get_meta：内部控件（PanelContainer/VBox/Label）没有这个 meta，
		# 而 get_meta(键, 默认值) 在键不存在时仍会打错误日志（就是刷屏的
		# "does not have any 'meta' values with the key 'ui_base'"）
		if not c.has_meta(UIBase.META_UI):
			continue
		var ui: UIBase = c.get_meta(UIBase.META_UI) as UIBase
		if ui != null and c.get_global_rect().has_point(pos):
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
		@warning_ignore("UNSAFE_PROPERTY_ACCESS")
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			@warning_ignore("UNSAFE_CAST")
			@warning_ignore("UNSAFE_PROPERTY_ACCESS")
			return (child.shape as RectangleShape2D).size
	return Vector2.ZERO
