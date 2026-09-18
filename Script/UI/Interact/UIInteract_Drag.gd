class_name UIInteract_Drag
extends UIInteractBase
## UI 交互：**按住拖动**（`UIInteract.drag`；配套的每帧执行是 `dragging`，同文件）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## ---- 按住类交互：一律写成一对（登记入口 + 每帧执行），配置里只写登记入口 ----
## 为什么成对：指令是字符串，只应该出现在配置里（散在代码里以后不好统一改），
## 所以指令只负责"说一声要干什么"，真正的"每帧干活"用代码里的 Callable 交给 AutoSys，
## 状态不满足时 AutoSys 自己删（见 Script/Auto/Auto.md），调用方不用写"松开"。


## 按住拖动 —— **登记入口**，配置里写 `UIInteract.drag $parent $event`
## （`$event` 由 UIBase._resolve_cmd 补成带引号的状态名，即"按住哪个状态时拖"）。
## 被谁用：MiniHUD 标题栏、整块键盘面板（UIPreset_Keyboard）。
static func drag(target: UIBase, status_name: String) -> void:
	var ui := _as_ui(target, "drag")
	if (ui == null) or (ui.control == null):
		return
	AutoSys.run_until_unsatisfied(Sys.sys_status, status_name, dragging.bind(ui))


## 按住拖动 —— **每帧执行**（不写在配置里，只由 AutoSys 调）：
## 把"指针本帧的累计位移"(InputSys.mouse_delta)作用到 UI 上。
## 指针移出 UI 也照拖（AutoSys 按状态驱动，不看 hover）；一帧一次，指针不动时位移 (0,0)，不会漂。
## 被谁用：AutoSys._process（经 drag 登记）。参数由 drag 绑定，这里不必再校验（不做重复判断）。
static func dragging(ui: UIBase) -> void:
	ui.control.position += InputSys.mouse_delta
