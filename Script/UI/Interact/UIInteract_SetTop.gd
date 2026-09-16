class_name UIInteract_SetTop
extends UIInteractBase
## UI 交互：**把 UI 提到最前**（`UIInteract.set_top`）——"点一下谁，谁在最上面"。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。

## 最近提到最前的**窗口**（见下）：同一个窗口再来就什么都不做。
## 为什么需要：HOLD 这类状态每帧都会派发一次，没有它就会每帧重排。
## 新开的 UI 也会走 set_top（open 里调），所以这份记录不会过期。
static var _front: UIBase = null


## 把 target 所在的**窗口**提到最前。注意是"窗口"，不是被点到的那一个元素：
## 沿 parent 链爬到最外层那个 UI（= 挂 UI 根的那个窗口）。
## **为什么不能直接对元素做 move_to_front()**（上一版的坑，两个后果同时出现）：
##   ① 同级窗口没被排过 ⇒ 看起来"根本没生效"；
##   ② 元素在 VBox / PanelContainer 里时，重排兄弟 = **改布局**，被点的小元素真的会跳位置
##      （表现为"子 UI 在面板里乱窜"）。窗口自己挂在 CanvasLayer 下（不是容器），重排才是安全的。
## 这也是 Unity 那边的做法（UISetTop：沿父链爬到前景层的孩子再置顶）。
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
	if window.control == null or window == _front:
		return
	_front = window
	window.control.move_to_front()
