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
## **下限 = 全局最小尺寸 与 这块 UI 自己需要的最小尺寸 取大者**：
##   前者见 Config/SystemConfig.gd（`SysCfg.resize_min_size`，保证手柄图标排得下）；
##   后者是内容最小尺寸（内容盒 + 内边距 + 底图边距，**含嵌套子 UI 的最小尺寸**，见 UIBase._content_size）。
## 缩到下限就**停住、不再跟着鼠标走**。为什么不只卡全局下限（只卡它踩过两个坑）：
##   · 面板明明已经缩到底（实际尺寸被内容顶住不再变小），手柄却在右下角、鼠标继续跑——
##     看着像"手柄跑到窗口中间"；
##   · 更糟的是嵌套 UI：外层面板缩得比内层子面板的最小尺寸还小，两层内容直接**叠在一起**
##     （容器不会把子元素压到它的最小尺寸以下，超出的部分就画到外面去了）。
## **位移要除以 scale**：`size` 是**父坐标**尺寸，而鼠标位移是**屏幕**位移——窗口被等比缩放
## （见 UIInteract_Rescale）后**视觉尺寸 = size × scale**，不除的话拖拽速度会差一个 scale 倍
## （缩小的窗口改尺寸会"跟不上鼠标"，实测踩过）。scale = 1 的普通窗口不受影响。
## 被谁用：AutoSys._process（经 resize 登记）。参数由 resize 绑定，这里不必再校验（不做重复判断）。
static func resizing(ui: UIBase) -> void:
	var delta: Vector2 = InputSys.mouse_delta
	if delta == Vector2.ZERO:
		return                       # 没动就不写配置（省掉每帧的 _fit_size）
	ui.config["fit_content"] = false # 先定"面板为准"，下面量最小尺寸要按这个模式算
	var s: float = ui.control.scale.x
	if s == 0.0:
		s = 1.0                      # 退化保护：scale 为 0 没有意义，按 1 算
	var floor_size: Vector2 = SysCfg.resize_min_size.max(ui._content_size())
	var want: Vector2 = (ui.control.size + delta / s).max(floor_size)
	ui.config["size"] = [want.x, want.y]
	ui._fit_size()                   # 按新尺寸重排（内容照新宽度折行、位置跟着锚点走）
