class_name QName
extends BaseClass
## 全局"名字表"：状态名之类的字符串集中在这里，避免同一个字符串散落多处（改名只改这一处）。
##
## 命名：一律**小写下划线**；只有 mouseLeft / mouseRight 保留驼峰。
## 这些名字是**同一个字符串的多处身份**：状态定义里的 name、快捷里的依赖状态名、
## UI 配置里的事件名 / `PointerDetect.key "<状态名>"` 里那个字符串——所以都用这里，改一处即可。

# ---- 输入监控（指针 / 键）----
static var pointer1_hold := "Pointer 1 Hold"
static var pointer2_hold := "Pointer 2 Hold"
static var pointer_move := "Pointer Move"       # 指针移动，**一个名字两种身份**：① PointerDetect 直接派发给
                                                # hover 元素的 **UI 事件**；② SYS 角色上的**瞬时状态**（这一帧动过就
                                                # 亮一下，见 Archetype_System）——延时指令的取消条件用后者
static var pointer_enter := "Pointer Enter"     # hover 进入（同上）
static var pointer_exit := "Pointer Exit"       # hover 离开（同上）
static var input_submit := "Input Submit"       # 输入框回车提交（编辑中按回车照常进状态链，QName.submit 满足时由状态侧派发；框里文字用 @self.control.text 读）
static var editing := "Editing"                 # "正在编辑输入框"：由 UIInteract_Edit 手动开 / 关的**保持型**外部检测
                                                # （状态里配 with_detect_manual，见 StatusPreset 与 UIInteract_Edit）

# 物理层（**只有这两个**；按下/松开/逐帧那些曾经有，没人用已删）：
# 鼠标键按住 = 一个状态，逻辑层的 pointer1_hold / pointer2_hold 依赖它（见 Archetype_System）。
static var mouseLeft := "Mouse Left"
static var mouseRight := "Mouse Right"
static var right := "Right"
static var up := "Up"
static var left := "Left"
static var down := "Down"
static var shift := "Shift"
static var submit := "Submit"
static var submit_on_what_keys := "Submit on What Keys"
static var key_j := "Key J"                     # 测试用：开关"显示"测试 UI
static var key_k := "Key K"                     # 测试用：开关"输入"测试 UI

# ---- UI 常态右键菜单（点在空地上右键开的那一扇，见 Archetype_System / UIPreset_Menu）----
static var pointer_on_ui := "Pointer On UI"     # 保持型状态：**指针下有没有 UI**（hover 变化时由 PointerDetect
                                                # 手动开/关，同 QName.editing 那套）；常态右键菜单靠它判"点在空地上"
static var desktop_menu := "Desktop Menu"       # 常态右键菜单该开：**右键按住 ∧ 指针不在任何 UI 上**（两个依赖）；
                                                # 满足时由快捷指令开出 "DesktopMenu"（开在指针处）
static var map_monitor_on := "Map Monitor On"   # **地图格实时监控是否启用**（保持型：由"此格瓦片"窗口里那个
                                                # 可选项手动开/关，同 QName.editing 那套）
static var map_monitor := "Map Monitor"         # 实时监控该刷了：**启用 ∧ 指针动过**（两个依赖）；
                                                # 满足时由快捷指令按鼠标所属格刷新 `MapCell`（见 UIPreset_MapCell）

# ---- 时间周期 ----
static var tick := "Tick"
static var hour_advance := "Hour Advance"
static var day_advance := "Day Advance"
static var xun_advance := "Xun Advance"
static var month_advance := "Month Advance"
static var year_advance := "Year Advance"

# ---- UI 事件（config["events"] 列表里的一项 = [事件名, 指令串]）----
## 常用的整体绑定放这儿：配置里**直接填这个变量**（如 `"events": [QName.UI_event_pointer1_drag]`），
## 于是同一条绑定只有一处写法（见 UIPreset_Menu 的 EnableDrag：往宿主 events 里开关它）。
## 带 `_host` 的那几条作用于**本条链的窗口**（`host`，见 指令系统（`@self`/`@host`/`@event`）），
## 所以它们挂在谁身上都行——不会因为多包一层分组就指错对象。
static var UI_event_pointer1_drag := [QName.pointer1_hold, "UIInteract.drag(@self, @event)"]
static var UI_event_pointer1_drag_host := [QName.pointer1_hold, "UIInteract.drag(@host, @event)"]
static var UI_event_pointer1_edit := [QName.pointer1_hold, 'UIInteract.begin_edit(@self)']
static var UI_event_pointer2_menu := [QName.pointer2_hold, 'UIInteract.open(@self, "Menu", @self, close_on_blur=true, host=@self)']
static var UI_event_pointer1_close_host := [QName.pointer1_hold, "UIInteract.close(@host)"]
static var UI_event_pointer1_rescale_host := [QName.pointer1_hold, "UIInteract.rescale(@host, @event)"]
static var UI_event_pointer1_resize_host := [QName.pointer1_hold, "UIInteract.resize(@host, @event)"]
static var UI_event_pointer1_fold_parent := [
	QName.pointer1_hold,
	'UIInteract.toggle_fold(@self.parent)'
	+ '\vUtils.swap("@self.config.content", "@self.config.content_2")'
	+ '\v@self.refresh("content")']

# ---- 共享常量：UI 配色（不是"名字"，但同理——**同一个值多处用 ⇒ 只留一处**）----
## 放这里的理由：这些值不只一个地方在用（`UIBase.reapply` / `UIBase._apply_caret` / `UI_Label.reapply` /
## `UI_View._row` …），而**颜色最容易在多处各写一遍**（`_row` 就写死过一份与默认字色一模一样的字面值，
## 于是改全局默认改不到它）。所以"默认长什么样"只在这里说一次，别处一律引用。
##
## ⚠️ 都是**按"浅色底"挑的**（面板底是浅色竹纸 / 白底圆角图，见 `SysCfg.ui_background`）：
## 引擎默认主题是给**深色**底配的（字与光标都接近白），画在浅底上等于看不见。想换回"深底浅字"，
## 改这一段就行（一处生效）；个别元素也能在自己的 config 里写同名键覆盖（`font_color` / `caret_color` …）。

## **正文默认字色**：没配 `font_color` 的元素就用它（见 UIBase.reapply / UI_Label.reapply）。
static var ui_font_color_default := Color(0.13, 0.13, 0.16)

## **输入框那根光标不是图，是颜色**：引擎用 `caret_color` 画一根 `caret_width` 像素宽的竖条
## （实测 LineEdit / TextEdit 只有"颜色 + 宽度"这两个主题项，**没有"放光标图"的槽**）——
## 所以给的是颜色，不是纹理（跟底图那张不是一回事）。引擎默认那根接近白（0.95,0.95,0.95），
## 跟浅色竹纸一个颜色 ⇒ 这就是"输入框看不见光标"的原因。想更显眼就调宽（2 已经很明显）。
static var ui_caret_color := Color(0.13, 0.13, 0.16)
static var ui_caret_width := 2

## **多行框里"当前行"那层底色**：引擎默认是**深色半透明**（0.25,0.25,0.26,0.8，也是给深色主题挑的）
## ⇒ 铺在浅色竹纸上就是一道灰黑横杠。换成"极淡的深色"（只当提示，不抢字）。
static var ui_input_line_color := Color(0.13, 0.13, 0.16, 0.06)

## **选中文字的底色**（输入框里选中的字 + "可选中"的展示文本，见 `UI_Label` 的 `selectable`）：
## 引擎默认是中灰 + 前景白/透明（"灰块 + 白字"在浅底上同样看不清）。换成淡青底；
## **前景色不另设**（用 `font_color` 那支深色画选中的字，见 UIBase._apply_caret）。
static var ui_selection_color := Color(0.42, 0.62, 0.75, 0.35)