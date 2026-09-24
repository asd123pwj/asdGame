class_name UIInteract_Resize
extends UIInteractBase
## UI 交互：**拖右下角改尺寸**（`UIInteract.resize`；配套的每帧执行是 `resizing`，同文件）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。
##
## **与 `UIInteract.rescale`（等比缩放）的分工**：
##   · 这个：**宽高各自加减**（像 Windows 拖窗口边角）⇒ 内容跟着折行、能多放/少放东西；
##   · 那个：整块按比例放大 ⇒ 字也跟着大（"整体变大一倍"是它，"我要看更多字"是这个）。
## 两个可以放在同一个角上（同一角的多个图标会自己排成一行，见 UI_Panel._corner_box）。


## 改尺寸 —— **登记入口**，配置里写 `UIInteract.resize(@host, @event)`（按住哪个状态时改）。
## 被谁用：SizeGrip 预设（见 UIPreset_Basic.gd）。
static func resize(target: UIBase, status_name: String) -> void:
	var ui := _as_ui(target, "resize")
	if (ui == null) or (ui.control == null):
		return
	AutoSys.run_until_unsatisfied(Sys.sys_status, status_name, resizing.bind(ui))


## 改尺寸 —— **每帧执行**（不写在配置里，只由 AutoSys 调）：把本帧的指针位移当成"宽高的增量"。
## 增量式 ⇒ 不用记按下时的抓手位置、不用管松手（状态不满足时 AutoSys 自己把登记删掉），
## 指针拖出面板也照样算。
## 尺寸**写回 `config["size"]`**（这样 `_fit_size` 认得它，下一次因内容/配置刷新时不会被顶回去），
## 同时把这块切成 **`fit_content = false`（面板为准）**：里面的文本改成照面板宽度折行 ——
## 于是"拖大 ⇒ 折行变少、拖小 ⇒ 折行变多"，而不是内容原样、只把边框拉大（见 UIBase._in_fixed_panel）。
## 下限取自 Config/SystemConfig.gd（`SysCfg.resize_min_size`）。
## 被谁用：AutoSys._process（经 resize 登记）。参数由 resize 绑定，这里不必再校验（不做重复判断）。
static func resizing(ui: UIBase) -> void:
	var delta: Vector2 = InputSys.mouse_delta
	if delta == Vector2.ZERO:
		return                       # 没动就不写配置（省掉每帧的 _fit_size）
	var want: Vector2 = (ui.control.size + delta).max(SysCfg.resize_min_size)
	ui.config["fit_content"] = false
	ui.config["size"] = [want.x, want.y]
	ui._fit_size()                   # 按新尺寸重排（内容照新宽度折行、位置跟着锚点走）
