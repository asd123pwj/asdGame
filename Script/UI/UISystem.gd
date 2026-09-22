class_name UISys
extends BaseClass
## UI 系统（设计见 Script/UI/UI.md）。
## 命名与其它系统对齐：类名用短名 `XxxSys`（`CharSys` / `TimeSys` / `MapSys` / `CmdSys` / `InputSys` 同理），
## 文件名保持 `XxxSystem.gd`——与 `CharacterSystem.gd`(CharSys)、`InputSystem.gd`(InputSys) 一套约定。
##
## 职责：**UI 树的登记与取件** + UI 根（`root`）。
## **"叫什么名字"不在这里**：登记名（`MiniHUD/Menu` 这种）与"实例 ID ↔ 注册名"两张表都在
## `RegSys`（通用注册名系统，见 Script/System/RegSystem.gd）——本类只负责"按 UI 树递归地调
## `RegSys.register`"，以及 UI 侧两个便利入口（`get_ui` / `find_name`）。以后别的系统要名字，
## 也走 RegSys 同一处（它当初就是为了"ID 对人不可读"而立的：UI 编辑器显示 config 时靠它认人）。
## **开启与失焦关闭都不在本类**：`open`（复用查找 + 摆位 + 显示）连同它的子方法
## `_build_open`/`_place`/`_child_ui` 放在 Script/UI/Interact/UIInteract_OpenClose.gd，
## 失焦关闭（`close_blur_ui`）也在那儿——候选只有"开出来的 UI"才可能有，记在 open 那边。
## 要改"怎么开、怎么摆、什么时候失焦关"都去那边。交互指令（开/关/拖动/缩放/渐隐/改内容）都在 `Script/UI/Interact/`。
## "按住期间每帧做的事"（如等比缩放）也不在本类：见 `AutoSys`（Script/Auto/Auto.md）。
##
## **UI 树怎么长**（挂载规则：anchor 优先 → 宿主 → UI 根）见 `UIInteract_OpenClose.open`——
## 它决定了"关谁连谁一起关"，也决定了指令里的 `@self.parent` 链（菜单链是一棵单链子树，
## `MiniHUD → Menu → Edit(菜单项) → MenuEdit → …`），所以失焦判定沿 parent 链就能认出"指针在我这条链上"
## （见 UIInteract_OpenClose.close_blur_ui）；关父级时整条链随可见性继承一起消失。
##
## **登记名规则**（唯一的"寻址"约定，两条都只是 `RegSys.join` 的用法）：
##   - 没有挂载点（独立 UI）→ 登记名就是预设名，如 `MiniHUD`；
##   - 有挂载点 → `挂载点的登记名 + "/" + 名字`，如 `MiniHUD/Menu`、
##     `MiniHUD/Menu/Edit/MenuEdit`（子菜单挂在菜单项下，名字也就层层接下去）。
##   **"开出来的 UI"与"配置里的子元素"共用这一条规则**（子 UI 的名字就是它的预设名），
##   所以登记表就是一整棵用 `/` 连接的树，看名字就知道挂在谁下面。
##   于是"同一个地方再开同一个 UI"就是**一次取件**（`RegSys.get_(登记名)`），
##   不需要"按同一宿主 + 同一预设遍历所有实例"这种特判。
##   注意同一挂载点下不要重名（RegSys.register 会警告并让后来者覆盖）。
##
## **成员全部是静态的**：日常调用直接写 `UISys.root` / `UISys.get_ui(...)` / `RegSys.get_(...)`，
## 不要绕 `Sys.uiSys`（那个实例只用来在启动时跑一次 `_init` 建 UI 根，见下）。

## UI 根的 CanvasLayer 层号：**必须高于地图**。地图每个子层用 `CanvasLayer.layer = 子层 id`
## （见 MapLayer：世界层 0 的六个子层 = 0~5，以后加世界层还会更大），默认值 1 会被地图的 1~5 盖住，
## 所以这里取一个明显更大的值，给以后加地图层留富余。
## 被谁用：_init（建根时设置）。
const ROOT_LAYER: int = 100
## UI 根（CanvasLayer）：所有"没有宿主"的 UI 都挂这里。
## 被谁用：_init（创建）、UIInteract_OpenClose._build_open（挂独立 UI）。
static var root: CanvasLayer


## 启动触发（**唯一的实例方法**）：建 UI 根并延迟挂到树上。
## 被谁用：Sys.init_sub_system（`uiSys = UISys.new()`）——别的地方不要 new 它，直接用静态成员。
func _init() -> void:
	root = CanvasLayer.new()
	root.name = "UIRoot"
	root.layer = ROOT_LAYER
	# 初始化发生在 Sys._ready()（引擎仍在建子节点），需延迟到本帧空闲再挂载
	Sys.sys.get_tree().root.add_child.call_deferred(root)


## 取一个已登记的 UI（用登记名，如 "MiniHUD"、"UI/MiniHUD/Menu"、"UI/MiniHUD/Menu/Close"）。
## 就是 `RegSys.get_(名字)` 加一层 UIBase 类型——配置里想让指令系统直接拿到 UI 就用它。
## 被谁用：Test.ui_test（拿滚动区改内容）、外部按名取子元素。
static func get_ui(reg_name: String) -> UIBase:
	return RegSys.get_(reg_name) as UIBase


## 反查一个已登记的 UI 叫什么（未登记给空串）——`RegSys.name_of` 的 UI 版。
## 被谁用：register_child（拼子元素登记名）、外部想知道"这个 UI 叫什么"。
static func find_name(ui: UIBase) -> String:
	return RegSys.name_of(ui)


## 让所有已登记的 UI 的界面跟自己的 config 一致（见 UIBase.refresh）。
## **首选不是它**：改了什么就刷什么（`self.refresh` / `UISys.get_ui(名字).refresh`），
## 一条改值指令配一条刷新。这里只是"实在要一把刷"时的兜底（如调试期、或改动散在很多 UI 上）。
## 成本 = UI 数量 × 一次刷新（都很轻：只镜像 + 设文本/可见性；位置不在这里，见 UIBase.refresh）。
## 正在编辑的输入框会自己跳过（别把人打的字冲掉，见 UI_Input.refresh）。
## 被谁用：配置里 `UISys.refresh_all`（要一把刷时的兜底）。
static func refresh_all() -> void:
	for each_name in RegSys.names():
		var ui: UIBase = RegSys.get_(each_name) as UIBase
		if ui != null:
			ui.refresh()


## 给已登记的 UI 追加一个子元素并登记（由 UIBase.add_child_element 调用）。
## 登记后才可能被指针命中；父元素没登记就警告（子元素会永远收不到事件）。
## 命名走 `RegSys.join`（`挂载点名/名字`），所以"开出来的 UI"与"配置里的子元素"是同一套名字。
## 被谁用：UIBase.add_child_element（配置子元素、以及 UIInteract_OpenClose._build_open 开的 UI）。
static func register_child(parent: UIBase, child: UIBase) -> void:
	if find_name(parent) == "":
		push_warning("UISys: 追加子元素「%s」时父元素未登记，该元素无法被指针命中" % child.name)
		return
	_register_tree(child, RegSys.join(parent, child.name))


## 登记整棵 UI 树：根用登记名，子元素用 "登记名/子名"（两张表都由 RegSys 维护）。
## 子元素也进登记表，PointerDetect 才能把指针命中派发到具体子元素（如关闭按钮、菜单项）。
## 登记名**热更新进配置**：于是"这个 UI 叫什么名字"是**读值**能拿到的数据
## （指令里写 `@注册名.config.reg_name`），不需要"反查名字"的函数。
## 改动 / 重开 / 追加子元素都会重新登记，所以它始终跟登记表一致。
## 被谁用：UIInteract_OpenClose._build_open（独立 UI）、register_child（子元素）。
static func _register_tree(ui: UIBase, full_name: String) -> void:
	RegSys.register(ui, full_name)
	ui.config["reg_name"] = full_name
	# 通知元素"你已经有名字了"：需要按名字做事的元素（如 UI_Editor 铺内容时子元素要登记）在这里补做。
	# 放在**自己的子元素递归之前**：这样它铺出来的子元素紧接着就一起被登记。
	ui.on_registered()
	for child in ui.children:
		_register_tree(child, full_name + "/" + child.name)
