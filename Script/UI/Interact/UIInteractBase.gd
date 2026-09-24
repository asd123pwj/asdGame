class_name UIInteractBase
extends BaseClass
## UI 交互指令宿主 —— **交互组的基类**，只放各组共用的东西（设计见 Script/UI/UI.md）。
##
## **对外只有一套指令名 `UIInteract.xxx`**（元素按事件发送，如 `UIInteract.close @self.parent`），
## 实现**按"交互"拆成多个文件**（一个交互一个文件，免得一个文件越写越长），每个文件都 `extends UIInteractBase`：
##   Interact/UIInteract_OpenClose.gd   开 / 关       → UIInteract.open / UIInteract.close
##   Interact/UIInteract_Drag.gd        按住拖动      → UIInteract.drag（+ 每帧 dragging）
##   Interact/UIInteract_Rescale.gd     等比缩放      → UIInteract.rescale（+ 每帧 rescaling）
##   Interact/UIInteract_Fade.gd        渐隐 / 渐显   → UIInteract.fade_to
##   Interact/UIInteract_Edit.gd        开始/结束编辑 → UIInteract.begin_edit / end_edit
##   Interact/UIInteract_Fold.gd        收起/展开     → UIInteract.fold / unfold / toggle_fold
##   （UI 编辑器没有专用交互：内容元素 Script/UI/UI/UI_Editor.gd 自己铺，展开用通用的 fold）
##   （改显示内容 / 对调配置不需要专门交互：写 config + 刷新是 `Utils.write` / `Utils.swap` + `self.refresh`）
##
## 拆文件对外看不出区别：**指令前缀在本类声明一次**（`CMD_HOST`），子类继承它，
## 于是这些文件里的静态方法全都注册成 `UIInteract.方法名`（机制见 CmdSys 的"命令前缀组"）。
## 所以**加一个交互 = 加一个 `UIInteract_Xxx.gd`**（`extends UIInteractBase` + 写静态方法），
## 指令名自动就是 `UIInteract.xxx`，不用再登记到任何表里。
##
## 各交互只做"指令参数 → 具体实现"的转发与校验；**共用的校验就是本类的 `_as_ui`**。
## target 为目标 UI 实例（指令里的 self/host 由 指令系统（`@self`/`@host`/`@event`） 转成 `@注册名`，链尾的 `.parent` 等由指令系统取值，
## 指令系统执行时按注册名取出实例，故这里收到的就是 UIBase）。

## 本组所有文件注册到哪个指令前缀下（子类继承；机制见 CmdSys.CMD_HOST_CONST）。
const CMD_HOST: String = "UIInteract"


## 组内共用：target 校验 —— 只接受 UIBase 实例。
## 传空属配置或调用写错，报警告指明是哪个指令、传了什么，不要静默吞掉。
## 被谁用：本组各交互的指令（`UIInteract.open` 例外：它允许宿主为空 = 开独立 UI，故不校验）。
static func _as_ui(target: UIBase, cmd_name: String) -> UIBase:
	if target == null:
		push_warning("UIInteract.%s: target 为空（检查指令里的 self / @self.parent 链是否对着了元素）" % cmd_name)
		return null
	# 控件为空 = 这个元素已经没了。**别报警**：最常见的是"点了一下就让所在的内容整段重建"——
	# 比如编辑器里点"[重建]"，命令把那一行（就是被点的元素自己）清掉重铺，而点击派发**之后**
	# 还会按命中结果调 set_top / drag 之类，这时拿到的是一个刚被移除的元素。晚到的信号，忽略就好。
	# （真正的配置写错是"引用解不出来" ⇒ target == null，上面那条会报。）
	if target.control == null:
		return null
	return target


## 组内共用：指针是不是落在 ui（或它的**子孙元素**）上 —— 从 hover 沿 parent 链上溯，能找到 ui 就算。
## 两个地方用的是同一条判据："子菜单 / 浮窗算不算还在我这条链上"（开出来的窗是"挂在锚点下的一扇独立子窗"，
## 指针从锚点移到窗上时 hover 就换人了；不判这一下，窗会被自己关掉——两处都实测踩过）。
## hover 传 null（指针不悬在任何 UI 上）时恒为 false。
## 被谁用：UIInteract_OpenClose._close_outside、UIInteract_Meta._hover_in_tips。
static func _in_subtree(ui: UIBase, hover: UIBase) -> bool:
	var cur: UIBase = hover
	while cur != null:
		if cur == ui:
			return true
		cur = cur.parent
	return false
