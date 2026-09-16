class_name UIInteract_Rescale
extends UIInteractBase
## UI 交互：**等比缩放**（`UIInteract.rescale`；配套的每帧执行是 `rescaling`，同文件）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## 等比缩放 —— **登记入口**，配置里写 `UIInteract.rescale $parent $event`。
## 被谁用：ResizeButton 预设（见 UIPreset_Basic.gd）。
static func rescale(target: UIBase, status_name: String) -> void:
	var ui := _as_ui(target, "rescale")
	if (ui == null) or (ui.control == null):
		return
	AutoSys.run_until_unsatisfied(Sys.sys_status, status_name, rescaling.bind(ui))


## 等比缩放 —— **每帧执行**（不写在配置里，只由 AutoSys 调）。
## 缩放怎么算：把本帧的指针位移折成缩放**增量** ——
##   `scale *= |指针 - 面板左上角| / |上帧指针 - 面板左上角|`
## 增量式所以**不需要跨帧记任何状态**（不用记抓手位置、不用注册/注销回调、不用监听松手），
## 且按下瞬间不跳变（从手柄任意位置按下去都跟手）；缩放中心是左上角。
## 沿对角线拖是像素级跟手；垂直于对角线的位移在数学上跟不了（等比只有一个自由度），这是固有代价。
## 上下限与保护值取自 Config/SystemConfig.gd（SysCfg.resize_min_scale / resize_max_scale / rescale_epsilon）。
## 指针移出 UI 也照缩 —— 执行由 AutoSys（状态层）驱动，与 hover 派发无关。
## 被谁用：AutoSys.update（经 rescale 登记）。参数由 rescale 绑定，这里不必再校验（不做重复判断）。
static func rescaling(ui: UIBase) -> void:
	ui.control.pivot_offset = Vector2.ZERO     # 缩放中心钉在左上角（不设就绕控件中心缩、位置乱跑）
	var anchor: Vector2 = ui.control.get_global_rect().position     # 左上角（pivot 为 0，缩放时它不动）
	var now: Vector2 = InputSys.mouse_position
	var before: Vector2 = now - InputSys.mouse_delta                # 上帧的指针位置
	var dist_before: float = maxf((before - anchor).length(), SysCfg.rescale_epsilon)
	var ratio: float = (now - anchor).length() / dist_before
	var scale: float = clampf(ui.control.scale.x * ratio, SysCfg.resize_min_scale, SysCfg.resize_max_scale)
	ui.control.scale = Vector2.ONE * scale
