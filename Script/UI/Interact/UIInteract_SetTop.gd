class_name UIInteract_SetTop
extends UIInteractBase
## UI 交互：**把 UI 提到最前**（`UIInteract.set_top`）——"点一下谁，谁在最上面"。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。

## 最近提到最前的**窗口**（见下）：同一个窗口再来就什么都不做。
## 为什么需要：HOLD 这类状态每帧都会派发一次，没有它就会每帧重排。
## 新开的 UI 也会走 set_top（open 里调），所以这份记录不会过期。
static var _front: UIBase = null
## 最近提到最前的**自由层元素**（见下）：同上，避免 HOLD 每帧重排。
static var _front_free: UIBase = null


## 把 target 提到最前——**分两级**：
##   · **窗口级**：沿 parent 链爬到最外层那个 UI（= 挂 UI 根的那个窗口），把窗口提到最前。
##     注意是"窗口"，不是被点到的那一个元素（上一版的坑，两个后果同时出现）：
##     ① 同级窗口没被排过 ⇒ 看起来"根本没生效"；
##     ② 元素在 VBox / PanelContainer 里时，重排兄弟 = **改布局**，被点的小元素真的会跳位置
##        （表现为"子 UI 在面板里乱窜"）。窗口自己挂在 CanvasLayer 下（不是容器），重排才是安全的。
##   · **自由层元素级**：往上爬到"第一个不是容器孩子的位置"（父节点不是 Container：
##     宿主的叠加层 / CanvasLayer / 网格区这类绝对定位层），把**那一层的孩子**提到最前。
##     为什么需要：菜单和它开出的手柄同挂在宿主叠加层里，只是**兄弟先后**——只提窗口提不动
##     它们之间的先后：先开菜单再开手柄，手柄排到了菜单前面；之后重开菜单，菜单仍旧被压在
##     手柄下面（实测踩过）。重排只发生在"父节点不是容器"的绝对定位层，容器（VBox 等）里的
##     元素一律爬过去不碰（重排容器兄弟 = 改布局）。
## 只需要一句 `move_to_front()`：**命中已经按控件树走**（PointerDetect._ui_at：同级倒序 + 孩子优先），
## 和绘制顺序是同一套顺序，所以不用再维护"登记顺序"（旧版那个要删了再写的 _bump_tree 已删）。
## 被谁用：PointerDetect.key（点它）、UIInteract_OpenClose.open（新开的排到最前）。
static func set_top(target: UIBase) -> void:
	var ui := _as_ui(target, "set_top")
	if ui == null or ui.control == null:
		return
	var window: UIBase = ui
	while window.parent != null:
		window = window.parent
	var free: UIBase = ui
	while free.parent != null and free.control.get_parent() is Container:
		free = free.parent
	if window == _front and free == _front_free:
		return                       # 同一窗口、同一自由层的同一个元素：上一轮已提过（HOLD 每帧派发，别重排）
	_front = window
	_front_free = free
	if window.control != null:
		window.control.move_to_front()
	if free != window and free.control != null and free.control.get_parent() != null:
		free.control.move_to_front()
