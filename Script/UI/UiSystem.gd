class_name UiSys
extends BaseClass
## UI 系统（设计见 Script/UI/UI.md）。
## 命名与其它系统对齐：类名用短名 `XxxSys`（`CharSys` / `TimeSys` / `MapSys` / `CmdSys` / `InputSys` 同理），
## 文件名保持 `XxxSystem.gd`——与 `CharacterSystem.gd`(CharSys)、`InputSystem.gd`(InputSys) 一套约定。
##
## 职责：UI 的**登记与寻址**——全项目唯一的登记表 `uis` 在本类：
## 登记（`register_child` / `_register_tree`）、取件（`get_ui`）与登记名规则（`_reg_name`）都在这。
## **开启与失焦关闭都不在本类**：`open`（复用查找 + 摆位 + 显示）连同它的子方法
## `_build_open`/`_place`/`_child_ui` 放在 Script/UI/Interact/UIInteract_OpenClose.gd，
## 失焦关闭（`close_blur_ui`）也在那儿——候选只有"开出来的 UI"才可能有，记在 open 那边。
## 要改"怎么开、怎么摆、什么时候失焦关"都去那边。交互指令（开/关/拖动/缩放/渐隐/改内容）都在 `Script/UI/Interact/`。
## "按住期间每帧做的事"（如等比缩放）也不在本类：见 `AutoSys`（Script/Auto/Auto.md，
## 状态满足期间每帧执行一条指令，状态不满足自动删——与指针在哪无关）。
##
## **UI 树怎么长**（挂载规则：anchor 优先 → 宿主 → UI 根）见 `UIInteract_OpenClose.open`——
## 它决定了"关谁连谁一起关"，也决定了指令里的 `$parent` 链（菜单链是一棵单链子树，
## `MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`），所以失焦判定沿 parent 链就能认出"指针在我这条链上"
## （见 UIInteract_OpenClose.close_blur_ui）；关父级时整条链随可见性继承一起消失。
##
## **登记名规则**（本类唯一的"寻址"约定，只有这一条）：
##   - 没有挂载点（独立 UI）→ 登记名就是预设名，如 `MiniHUD`；
##   - 有挂载点 → 登记名 = `挂载点的登记名 + "/" + 名字`，如 `MiniHUD/Menu`、
##     `MiniHUD/Menu/Edit/MenuEdit`（子菜单挂在菜单项下，名字也就层层接下去）。
##   **"开出来的 UI"与"配置里的子元素"共用这一条规则**（子 UI 的名字就是它的预设名），
##   所以登记表就是一整棵用 `/` 连接的树，看名字就知道挂在谁下面。
##   于是"同一个地方再开同一个 UI"就是**一次字典查找**（`uis.get(登记名)`），
##   不需要"按同一宿主 + 同一预设遍历所有实例"这种特判。
##   注意同一挂载点下不要重名（会互相覆盖）。
##
## **成员全部是静态的**：日常调用直接写 `UiSys.uis` / `UiSys.root` / `UiSys.get_ui(...)`，
## 不要绕 `Sys.uiSys`（那个实例只用来在启动时跑一次 `_init` 建 UI 根，见下）。

## UI 根的 CanvasLayer 层号：**必须高于地图**。地图每个子层用 `CanvasLayer.layer = 子层 id`
## （见 MapLayer：世界层 0 的六个子层 = 0~5，以后加世界层还会更大），默认值 1 会被地图的 1~5 盖住，
## 所以这里取一个明显更大的值，给以后加地图层留富余。
## 被谁用：_init（建根时设置）。
const ROOT_LAYER: int = 100

## UI 根（CanvasLayer）：所有"没有宿主"的 UI 都挂这里。
## 被谁用：_init（创建）、UIInteract_OpenClose._build_open（挂独立 UI）。
static var root: CanvasLayer
## 已登记的 UI：登记名 -> 实例（规则见文件头）——**只是"按名取件"的字典，顺序没有含义**：
## 指针命中已改为沿控件树走（见 PointerDetect._ui_at），前后关系由 CanvasLayer + 节点树序决定。
## 被谁用：UIInteract_OpenClose.open / _child_ui（复用查找与取件）、get_ui（按名取）、find_name（反查）。
static var uis: Dictionary[String, UIBase] = {}


## 启动触发（**唯一的实例方法**）：建 UI 根并延迟挂到树上。
## 被谁用：Sys.init_sub_system（`uiSys = UiSys.new()`）——别的地方不要 new 它，直接用静态成员。
func _init() -> void:
	root = CanvasLayer.new()
	root.name = "UIRoot"
	root.layer = ROOT_LAYER
	# 初始化发生在 Sys._ready()（引擎仍在建子节点），需延迟到本帧空闲再挂载
	Sys.sys.get_tree().root.add_child.call_deferred(root)


## 取一个已登记的 UI（用登记名，如 "MiniHUD"、"MiniHUD/Menu"、"MiniHUD/Menu/Close"）。
## 被谁用：Test.ui_test（拿滚动区改内容）、外部按名取子元素。
static func get_ui(name: String) -> UIBase:
	return uis.get(name)


## 给已登记的 UI 追加一个子元素并登记（由 UIBase.add_child_element 调用）。
## 登记后才可能被指针命中；父元素没登记就警告（子元素会永远收不到事件）。
## 命名就用 _reg_name 那一套（挂载点名 + "/" + 名字），所以"开出来的 UI"与"配置里的子元素"是同一套名字。
## 被谁用：UIBase.add_child_element（配置子元素、以及 UIInteract_OpenClose._build_open 开的 UI）。
static func register_child(parent: UIBase, child: UIBase) -> void:
	if find_name(parent) == "":
		push_warning("UiSys: 追加子元素「%s」时父元素未登记，该元素无法被指针命中" % child.name)
		return
	_register_tree(child, _reg_name(parent, child.name))


## 反查一个已登记 UI 的登记名（未登记返回空串）。
## 被谁用：_reg_name（拼"挂载点名/名字"）、register_child（拼子元素的登记名）。
static func find_name(ui: UIBase) -> String:
	for key in uis:
		if uis[key] == ui:
			return key
	return ""


## 拼登记名：**只有这一条规则**——无挂载点 → 名字就是预设名（独立 UI，如 `MiniHUD`）；
## 有挂载点 → `挂载点的登记名/名字`（子 UI 与配置子元素共用同一套，如 `MiniHUD/Menu/Edit/MenuEdit`）。
## 于是"同一个地方再开同一个 UI"就是一次字典查找（见 UIInteract_OpenClose.open），不需要按 UI 类型特判。
## 注意同一挂载点下不要重名（会互相覆盖）：子 UI 的名字就是它的预设名。
## 被谁用：register_child（拼子元素登记名）、UIInteract_OpenClose._child_ui（开/关取件）。
static func _reg_name(mount: UIBase, preset_name: String) -> String:
	if mount == null:
		return preset_name
	var mount_name: String = find_name(mount)
	if mount_name == "":
		push_warning("UiSys._reg_name: 挂载点「%s」未登记，拼不出唯一登记名，退化为预设名" % mount.name)
		return preset_name
	return mount_name + "/" + preset_name


## 登记整棵 UI 树：根用登记名，子元素用 "登记名/子名"。
## 子元素也进 uis，PointerDetect 才能把指针命中派发到具体子元素（如关闭按钮、菜单项）。
## 被谁用：UIInteract_OpenClose._build_open（独立 UI）、register_child（子元素）。
static func _register_tree(ui: UIBase, full_name: String) -> void:
	uis[full_name] = ui
	for child in ui.children:
		_register_tree(child, full_name + "/" + child.name)


## 失焦关闭（配 `close_on_blur` 的 UI 指针一离开就关）不在这里：候选只有"开出来的 UI"才可能有，
## 所以它在开/关那边（Script/UI/Interact/UIInteract_OpenClose.gd 的 close_blur_ui）。


## 逐帧回调与"按住期间每帧执行"都搬到 AutoSys 了（见 Script/Auto/Auto.md）：
## 那边按"角色 + 状态名 + 指令"登记，状态一端满足就自动停，不用在这里存 Callable。
