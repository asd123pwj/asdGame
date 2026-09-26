class_name UIPreset_Keyboard
extends ConfigBase

""" ---------- 键盘快捷键界面 ----------
冒险岛式的快捷键设置界面：一整块面板底图，上面按真实键盘的位置摆出每个键，
每个键里写"键名 + 当前绑定的操作"。

**整个界面只用这一份配置**：`values` 里只有一个 `Keyboard` 预设，键位子元素由下面的表算出来
（表外计算、values 引用结果——所以改 SCALE 就整体缩放，不用手抄上百行坐标）。
- 键位表 `KEYS` 的列：**[键码, x, 行, 尺寸, 键上显示的文本] (+ 可选：左右位置)**。
  键码用 Godot 的 `Key` 常量（`KEY_ESCAPE` / `KEY_Q` / `KEY_KP_8`…）——**它才是这个键的身份**：
  以后"点某个键 → 把它绑到某操作"就是拿 `config["key_code"]` 造 `InputEventKey`；
  最后一列只是**给人看的文本**（"Esc"、"Space"…）。
  左右修饰键（Shift/Ctrl/Alt 各有左右两个）在 Godot 里 keycode 相同、靠 `InputEventKey.location` 区分，
  所以它们多一列 `KEY_LOCATION_LEFT/RIGHT`；元素名也带 `_L`/`_R` 后缀，不然两个键会撞名互相覆盖。
- x/行/尺寸照原样写 Unity 那版的表达式（`32*2`、`row1 = -36*2`…），统一再乘 SCALE（1.0 = 与 Unity 同尺寸）。
- 整块面板可以按住拖动（按住 → `UIInteract.drag self event` 登记 → 每帧 `dragging`，和 MiniHUD 标题栏同一套）。
- 底图：**不用写**——面板与键都是 `UI_Panel`，不写 `background` 就自带**全项目默认那张**（`SysCfg.ui_background`：
  浅色圆角图，见 UI_Panel._apply_background）。字色/字号才要配（`font_color` / `font_size`：
  默认字色已是深色，这里显式写出来是为了"一眼看出这些键上的字是什么色"）。
- 以后给某个键绑操作：改它的描述文本即可，登记名 = `Keyboard/键名/Desc`
  （键名由键码生成，如 `Keyboard/Key_Q/Desc`、`Keyboard/Key_Kp8/Desc`、`Keyboard/Key_Shift_L/Desc`）。
- 开启：独立 UI，`UIInteract.open(preset_name="Keyboard")`；
  右上角的 "X" 就是普通预设 CloseButton（见 UIPreset_Basic），开启方一并开/关即可（见 Test.ui_test）。
"""

## Unity 数值 → 本项目像素的缩放（表里数值保持与 Unity 一致，不要改成算完的数）。
## 1.0 = 与 Unity 同尺寸：面板 1600×576、键 64×64（比默认窗口 1152×648 大，窗口够大时才摆得开）。
## 想缩进小窗口就调小它（如 0.7 ⇒ 1120×403）。
const SCALE: float = 1.0

## 整块面板 / 每个键的底图：**都在这里不写**——`UI_Panel` 没配 `background` 就用全项目默认那一张
## （`SysCfg.ui_background`，浅色圆角图；九宫格边距也是全局值 `SysCfg.ui_background_slice`）。
## 想给键盘单独换底：在这两个地方写 `"background"` / `"background_slice"`（写法见 UIPreset_Keyboard 之外的那些预设）。
## 键里文字的字号、字色（Unity 的 UIKeyName/UIKeyDescription 是 16；这里取 13，比原文小一点键里放得下）。
## 注意字号**不跟着 SCALE 走**，改 SCALE 后要自己看着调。
## 主题重写不向下传，所以配在每个键的那两行文本身上；字色显式给（浅底上要深色字，与全局默认同一个色）。
const FONT_SIZE: int = 13
const FONT_COLOR: Color = Color(0.13, 0.13, 0.16)
## 还没绑操作时，键的描述里显示的占位文本。
const DESC_PLACEHOLDER: String = "占位符"

## 面板尺寸（Unity：sizeDelta = new (800*2, 288*2)）。
const PANEL: Vector2 = Vector2(800 * 2, 288 * 2)
## 面板初始位置（本项目像素；独立 UI 重开时摆回这里）。
## SCALE=1.0 时面板是 1600×576，别让它超出窗口（按当前窗口大小调这个值）。
const PANEL_POSITION: Vector2 = Vector2(16, 122)

## 键的几种尺寸（照 Unity：keySize_small / middle / large / large_T / huge / veryHuge）。
const SMALL: Vector2 = Vector2(32 * 2, 32 * 2)      # 普通键
const MIDDLE: Vector2 = Vector2(50 * 2, 32 * 2)     # 中等：Tab / Enter / Ctrl / Alt / Win / Menu
const LARGE: Vector2 = Vector2(68 * 2, 32 * 2)      # 长：Caps / 右 Shift / 小键盘 0
const LARGE_T: Vector2 = Vector2(32 * 2, 68 * 2)    # 竖长：小键盘 + / Enter（占两行）
const HUGE: Vector2 = Vector2(86 * 2, 32 * 2)       # 很长：左 Shift
const VERY_HUGE: Vector2 = Vector2(194 * 2, 32 * 2) # 超长：空格

## 六行键的纵向位置（照 Unity：row1..row6，数值为负表示向下）。
const ROW1: float = -36 * 2
const ROW2: float = -76 * 2
const ROW3: float = -112 * 2
const ROW4: float = -148 * 2
const ROW5: float = -184 * 2
const ROW6: float = -220 * 2

## 键位表：[键码, x, 行, 尺寸, 键上显示的文本, (可选)左右位置]。
## x/行/尺寸照 Unity 原样；键码是 Godot 的 Key 常量（元素名与"这个键是谁"都由它来）。
const KEYS: Array[Array] = [
    # 第 1 行：Esc / F1-F12 / Psc / Slk / Brk
    [KEY_ESCAPE, 11 * 2, ROW1, SMALL, "Esc"],
    [KEY_F1, 83 * 2, ROW1, SMALL, "F1"],
    [KEY_F2, 119 * 2, ROW1, SMALL, "F2"],
    [KEY_F3, 155 * 2, ROW1, SMALL, "F3"],
    [KEY_F4, 191 * 2, ROW1, SMALL, "F4"],
    [KEY_F5, 236 * 2, ROW1, SMALL, "F5"],
    [KEY_F6, 272 * 2, ROW1, SMALL, "F6"],
    [KEY_F7, 308 * 2, ROW1, SMALL, "F7"],
    [KEY_F8, 344 * 2, ROW1, SMALL, "F8"],
    [KEY_F9, 389 * 2, ROW1, SMALL, "F9"],
    [KEY_F10, 425 * 2, ROW1, SMALL, "F10"],
    [KEY_F11, 461 * 2, ROW1, SMALL, "F11"],
    [KEY_F12, 497 * 2, ROW1, SMALL, "F12"],
    [KEY_PRINT, 537 * 2, ROW1, SMALL, "Psc"],
    [KEY_SCROLLLOCK, 573 * 2, ROW1, SMALL, "Slk"],
    [KEY_PAUSE, 609 * 2, ROW1, SMALL, "Brk"],
    # 第 2 行：数字行 + 编辑键 + 小键盘上半
    [KEY_QUOTELEFT, 11 * 2, ROW2, SMALL, "`"],
    [KEY_1, 47 * 2, ROW2, SMALL, "1"],
    [KEY_2, 83 * 2, ROW2, SMALL, "2"],
    [KEY_3, 119 * 2, ROW2, SMALL, "3"],
    [KEY_4, 155 * 2, ROW2, SMALL, "4"],
    [KEY_5, 191 * 2, ROW2, SMALL, "5"],
    [KEY_6, 227 * 2, ROW2, SMALL, "6"],
    [KEY_7, 263 * 2, ROW2, SMALL, "7"],
    [KEY_8, 299 * 2, ROW2, SMALL, "8"],
    [KEY_9, 335 * 2, ROW2, SMALL, "9"],
    [KEY_0, 371 * 2, ROW2, SMALL, "0"],
    [KEY_MINUS, 407 * 2, ROW2, SMALL, "-"],
    [KEY_EQUAL, 443 * 2, ROW2, SMALL, "="],
    [KEY_BACKSPACE, 479 * 2, ROW2, MIDDLE, "Backspace"],
    [KEY_INSERT, 537 * 2, ROW2, SMALL, "Ins"],
    [KEY_HOME, 573 * 2, ROW2, SMALL, "Home"],
    [KEY_PAGEUP, 609 * 2, ROW2, SMALL, "PgUp"],
    [KEY_NUMLOCK, 649 * 2, ROW2, SMALL, "Num"],
    [KEY_KP_DIVIDE, 685 * 2, ROW2, SMALL, "/"],
    [KEY_KP_MULTIPLY, 721 * 2, ROW2, SMALL, "*"],
    [KEY_KP_SUBTRACT, 757 * 2, ROW2, SMALL, "-"],
    # 第 3 行：Tab + QWERTY + 编辑键 + 小键盘 7/8/9/+
    [KEY_TAB, 11 * 2, ROW3, MIDDLE, "Tab"],
    [KEY_Q, 65 * 2, ROW3, SMALL, "Q"],
    [KEY_W, 101 * 2, ROW3, SMALL, "W"],
    [KEY_E, 137 * 2, ROW3, SMALL, "E"],
    [KEY_R, 173 * 2, ROW3, SMALL, "R"],
    [KEY_T, 209 * 2, ROW3, SMALL, "T"],
    [KEY_Y, 245 * 2, ROW3, SMALL, "Y"],
    [KEY_U, 281 * 2, ROW3, SMALL, "U"],
    [KEY_I, 317 * 2, ROW3, SMALL, "I"],
    [KEY_O, 353 * 2, ROW3, SMALL, "O"],
    [KEY_P, 389 * 2, ROW3, SMALL, "P"],
    [KEY_BRACKETLEFT, 425 * 2, ROW3, SMALL, "["],
    [KEY_BRACKETRIGHT, 461 * 2, ROW3, SMALL, "]"],
    [KEY_BACKSLASH, 497 * 2, ROW3, SMALL, "\\"],
    [KEY_DELETE, 537 * 2, ROW3, SMALL, "Del"],
    [KEY_END, 573 * 2, ROW3, SMALL, "End"],
    [KEY_PAGEDOWN, 609 * 2, ROW3, SMALL, "PgDn"],
    [KEY_KP_7, 649 * 2, ROW3, SMALL, "7"],
    [KEY_KP_8, 685 * 2, ROW3, SMALL, "8"],
    [KEY_KP_9, 721 * 2, ROW3, SMALL, "9"],
    [KEY_KP_ADD, 757 * 2, ROW3, LARGE_T, "+"],
    # 第 4 行：Caps + ASDF + 小键盘 4/5/6（"+" 从上一行压到这里）
    [KEY_CAPSLOCK, 11 * 2, ROW4, LARGE, "Caps"],
    [KEY_A, 83 * 2, ROW4, SMALL, "A"],
    [KEY_S, 119 * 2, ROW4, SMALL, "S"],
    [KEY_D, 155 * 2, ROW4, SMALL, "D"],
    [KEY_F, 191 * 2, ROW4, SMALL, "F"],
    [KEY_G, 227 * 2, ROW4, SMALL, "G"],
    [KEY_H, 263 * 2, ROW4, SMALL, "H"],
    [KEY_J, 299 * 2, ROW4, SMALL, "J"],
    [KEY_K, 335 * 2, ROW4, SMALL, "K"],
    [KEY_L, 371 * 2, ROW4, SMALL, "L"],
    [KEY_SEMICOLON, 407 * 2, ROW4, SMALL, ";"],
    [KEY_APOSTROPHE, 443 * 2, ROW4, SMALL, "'"],
    [KEY_ENTER, 479 * 2, ROW4, MIDDLE, "Enter"],
    [KEY_KP_4, 649 * 2, ROW4, SMALL, "4"],
    [KEY_KP_5, 685 * 2, ROW4, SMALL, "5"],
    [KEY_KP_6, 721 * 2, ROW4, SMALL, "6"],
    # 第 5 行：Shift + ZXCV + 方向键 + 小键盘 1/2/3/Enter
    [KEY_SHIFT, 11 * 2, ROW5, HUGE, "Shift", KEY_LOCATION_LEFT],
    [KEY_Z, 101 * 2, ROW5, SMALL, "Z"],
    [KEY_X, 137 * 2, ROW5, SMALL, "X"],
    [KEY_C, 173 * 2, ROW5, SMALL, "C"],
    [KEY_V, 209 * 2, ROW5, SMALL, "V"],
    [KEY_B, 245 * 2, ROW5, SMALL, "B"],
    [KEY_N, 281 * 2, ROW5, SMALL, "N"],
    [KEY_M, 317 * 2, ROW5, SMALL, "M"],
    [KEY_COMMA, 353 * 2, ROW5, SMALL, ","],
    [KEY_PERIOD, 389 * 2, ROW5, SMALL, "."],
    [KEY_SLASH, 425 * 2, ROW5, SMALL, "/"],
    [KEY_SHIFT, 461 * 2, ROW5, LARGE, "Shift", KEY_LOCATION_RIGHT],
    [KEY_UP, 573 * 2, ROW5, SMALL, "Up"],
    [KEY_KP_1, 649 * 2, ROW5, SMALL, "1"],
    [KEY_KP_2, 685 * 2, ROW5, SMALL, "2"],
    [KEY_KP_3, 721 * 2, ROW5, SMALL, "3"],
    [KEY_KP_ENTER, 757 * 2, ROW5, LARGE_T, "Enter"],
    # 第 6 行：Ctrl/Win/Alt/空格 + 方向键 + 小键盘 0/.
    [KEY_CTRL, 11 * 2, ROW6, MIDDLE, "Ctrl", KEY_LOCATION_LEFT],
    [KEY_META, 65 * 2, ROW6, MIDDLE, "Win"],
    [KEY_ALT, 119 * 2, ROW6, MIDDLE, "Alt", KEY_LOCATION_LEFT],
    [KEY_SPACE, 173 * 2, ROW6, VERY_HUGE, "Space"],
    [KEY_ALT, 371 * 2, ROW6, MIDDLE, "Alt", KEY_LOCATION_RIGHT],
    [KEY_MENU, 425 * 2, ROW6, MIDDLE, "Menu"],
    [KEY_CTRL, 479 * 2, ROW6, MIDDLE, "Ctrl", KEY_LOCATION_RIGHT],
    [KEY_LEFT, 537 * 2, ROW6, SMALL, "Left"],
    [KEY_DOWN, 573 * 2, ROW6, SMALL, "Down"],
    [KEY_RIGHT, 609 * 2, ROW6, SMALL, "Right"],
    [KEY_KP_0, 649 * 2, ROW6, LARGE, "0"],
    [KEY_KP_PERIOD, 721 * 2, ROW6, SMALL, "."],
]

## 算好的键位子元素与面板尺寸（脚本加载时算一次，values 直接引用）。
static var _layout: Dictionary = _build_layout()


## 键的元素名：由键码字符串生成（Escape→Key_Escape、Kp 8→Key_Kp8、Slash→Key_Slash）。
## 左右修饰键再带 _L/_R——Godot 里左右 Shift/Ctrl/Alt 的 keycode 相同，靠 location 区分，
## 名字不区分的话两个键会注册到同一个名下、互相覆盖。
## 被谁用：_build_layout。
static func _key_node_name(code: Key, location: KeyLocation) -> String:
	var raw: String = OS.get_keycode_string(code)
	var cleaned := ""
	for i in raw.length():
		var c: String = raw[i]
		if (c >= "0" and c <= "9") or (c.to_upper() != c.to_lower()):
			cleaned += c
	if cleaned == "":
		cleaned = str(code)   # 万一全是符号，用键码兜底，保证唯一
	if location == KEY_LOCATION_LEFT:
		cleaned += "_L"
	elif location == KEY_LOCATION_RIGHT:
		cleaned += "_R"
	return "Key_" + cleaned


## 把键位表编译成 config 用的 children：每个键 = 一个带底图的小面板 + "键名 / 操作描述"两行文本。
## 循环生成而不是手写上百行配置：表里是 Unity 的原数值，这里统一乘 SCALE。
## 被谁用：_layout 的初始化。
static func _build_layout() -> Dictionary:
	var children: Array[Array] = []
	var used_names := {}
	for k: Array in KEYS:
		var code: Key = k[0]
		var location: KeyLocation = k[5] if k.size() > 5 else KEY_LOCATION_UNSPECIFIED
		var node_name: String = _key_node_name(code, location)
		if used_names.has(node_name):
			push_warning("UIPreset_Keyboard: 元素名重复「%s」（键码 %d / %d），同一个名字会互相覆盖" % [node_name, used_names[node_name], code])
		used_names[node_name] = code
		var key_size: Vector2 = k[3]
		var row: float = k[2]
		children.append([node_name, "UI_Panel", {
			"free": true,                                      # 绝对定位：键盘按坐标摆，不进父级竖排布局
			"position": [float(k[1]) * SCALE, -row * SCALE],    # 行的负值（Unity 向下）→ 本项目的正坐标
			"size": [key_size.x * SCALE, key_size.y * SCALE],
			# 底图不写：`UI_Panel` 自带全项目默认那张（见文件头）
			# 这个键的身份：以后"点它 → 绑到某操作"就是拿这两个值造 InputEventKey
			"key_code": code,
			"key_location": location,
			"children": [
				["Name", "UI_Label", {
					"content": str(k[4]), "font_size": FONT_SIZE, "font_color": FONT_COLOR,
				}],
				["Desc", "UI_Label", {
					"content": DESC_PLACEHOLDER, "font_size": FONT_SIZE, "font_color": FONT_COLOR,
				}],
			],
		}])
	return { "children": children, "size": [PANEL.x * SCALE, PANEL.y * SCALE] }


var values: Array[Array] = [
    ["Keyboard", "UI_Panel", {
        "position": [PANEL_POSITION.x, PANEL_POSITION.y],
        "size": _layout["size"],                      # 底图不写：`UI_Panel` 自带全项目默认那张（见文件头）
        # 整块面板按住拖动（子元素没配这个事件时会冒泡到这里）；和 MiniHUD 标题栏是同一套。
        # 这条绑定也随时能被菜单项"启用/移除拖拽"加删（switch_value 直接开关这个列表，见 UIPreset_Menu）。
        "events": [QName.UI_event_pointer1_drag],
        "children": _layout["children"],
    }],
]
