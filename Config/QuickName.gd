class_name QName
extends BaseClass
## 全局"名字表"：状态名之类的字符串集中在这里，避免同一个字符串散落多处（改名只改这一处）。
##
## 命名：一律**小写下划线**；只有 mouseLeft / mouseRight 保留驼峰。
## 这些名字是**同一个字符串的多处身份**：状态定义里的 name、快捷里的依赖状态名、
## UI 配置里的事件名 / `PointerDetect.key "<状态名>"` 里那个字符串——所以都用这里，改一处即可。

# ---- 输入监控（指针 / 键）----
static var pointer_move := "Pointer Move"       # 指针移动（不是状态，由 PointerDetect 直接派发）
static var pointer_enter := "Pointer Enter"     # hover 进入（同上）
static var pointer_exit := "Pointer Exit"       # hover 离开（同上）
static var input_submit := "Input Submit"       # 输入框回车提交（编辑中按回车由 InputSys 派发；框里文字用 @self.control.text 读）
static var mouseLeft_press := "Mouse Left | Press"
static var mouseLeft := "Mouse Left"
static var mouseLeft_tick := "Mouse Left | Tick"
static var mouseLeft_release := "Mouse Left | Release"
static var mouseRight := "Mouse Right"
static var right := "Right"
static var up := "Up"
static var left := "Left"
static var down := "Down"
static var submit := "Submit"
static var key_j := "Key J"                     # 测试用：开关"显示"测试 UI
static var key_k := "Key K"                     # 测试用：开关"输入"测试 UI

# ---- 时间周期 ----
static var tick := "Tick"
static var hour_advance := "Hour Advance"
static var day_advance := "Day Advance"
static var xun_advance := "Xun Advance"
static var month_advance := "Month Advance"
static var year_advance := "Year Advance"

# ---- UI 事件（config["events"] 列表里的一项 = [事件名, 指令串]）----
## 常用的整体绑定放这儿：配置里**直接填这个变量**（如 `"events": [QName.UI_event_mouseLeft_drag]`），
## 于是同一条绑定只有一处写法（见 UIPreset_Menu 的 EnableDrag：往宿主 events 里开关它）。
## 带 `_host` 的那几条作用于**本条链的窗口**（`host`，见 指令系统（`@self`/`@host`/`@event`）），
## 所以它们挂在谁身上都行——不会因为多包一层分组就指错对象。
static var UI_event_mouseLeft_drag := [QName.mouseLeft, "UIInteract.drag(@self, @event)"]
static var UI_event_mouseLeft_drag_host := [QName.mouseLeft, "UIInteract.drag(@host, @event)"]
static var UI_event_mouseLeft_edit := [QName.mouseLeft, 'UIInteract.begin_edit(@self)']
static var UI_event_mouseRight_menu := [QName.mouseRight, 'UIInteract.open(@self, "Menu", @self, close_on_blur=true, host=@self)']
static var UI_event_mouseLeft_close_host := [QName.mouseLeft, "UIInteract.close(@host)"]
static var UI_event_mouseLeft_close_parent := [QName.mouseLeft, "UIInteract.close(@self.parent)"]
static var UI_event_mouseLeft_rescale_host := [QName.mouseLeft, "UIInteract.rescale(@host, @event)"]