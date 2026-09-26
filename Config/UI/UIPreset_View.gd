class_name UIPreset_View
extends ConfigBase

""" ---------- 角色数据看板（6 个一览摆在一块面板里） ----------
一块面板 = **屏幕的 3/4**（`size_ratio`，开在屏幕正中），标题下面按 **2 行 3 列**的二维矩阵分成 6 格，
六个一览各占一格：

  ▾ 角色数据                              ← 头部（可折叠标题：点它整块收起 / 展开）
  ┌──────────────┬──────────────┬──────────────┐
  │ 角色状态      │ 角色属性      │ 角色交互      │
  ├──────────────┼──────────────┼──────────────┤
  │ 角色技能      │ 系统快捷      │ 角色原型      │
  └──────────────┴──────────────┴──────────────┘
  （右上角一个图标关闭）

- **一格一个一览元素**（`Script/UI/UI/UI_View.gd` 那一族；抬头 / [刷新] / 一条一段 / 实时刷新都归元素自己，
  见各元素的文件头）：状态 / 属性 / 交互 / 技能 / 快捷 / 原型。
- **格内自己滚**：格子尺寸由矩阵算定（`UI_Panel` 的 `matrix` + 子元素的 `grid`），装不下的部分在**格内**滚。

**为什么这么配**：
  · **尺寸按屏幕比例**（`size_ratio: [0.75, 0.75]`，见 UIBase._config_size）：1920×1080 上就是 1440×810，
    换 2560×1440 自动变 1920×1080——"占屏幕多少"这件事不跟着分辨率改数字；
  · **每格写一个 `max_chars`**（`CELL_CHARS`）= "一栏文字最多多宽"：格子比原来那 6 个独立窗口**窄**
    （3/4 屏 ÷ 3 列 ≈ 470px），还按全局默认的 48 个字符（≈480px）走，长行右边会被裁掉一块
    ——所以要按格子宽反推一个值（怎么来的见 `CELL_CHARS`）；
  · 右上角一个图标关闭（`UIPreset_Basic.close_item()`，`free` ⇒ 挂叠加层，钉在右上角）；
    右键开管理菜单（关闭 / 复制名称 / 菜单编辑…）。
  · **不用 `fit_content: false`（"以面板为准"）来实现"照格子宽折行"**：试过，在"矩阵格子 + 格内滚动"
    这套上会让 Godot 4.7 **直接崩**（signal 11，二分到它：去掉这个键就不崩）。见 `CELL_CHARS` 的说明。

**看哪个角色**：见下表最后一列（状态 / 快捷看系统角色，其余看玩家角色）。
想临时换人：`UIInteract.open(preset_name="RoleData", content_cmd="@Char/人类")`——
`content_cmd` 写在**看板**上，六个格子都读它，所以是"整块一起换人"（各格自己的 `char` 是默认值）。

**加一格 / 换排布**：`CELLS` 加一行 + `MATRIX` 改成对应的编号（矩阵语义见 UI_Panel 的文件头：
同一个编号出现几格 = 那个元素跨几格 / 跨几行）。
"""

## 看板里的 6 格：**元素类**、默认看的角色（顺序 = 矩阵里的编号 1…6，见 MATRIX）。
## 元素名 = 类名去掉 `UI_` 前缀（`UI_Status` → `Status`），登记名好认。
const CELLS: Array[Array] = [
	["UI_Status",      "@Char/SYS"],     # 1 左上：角色状态
	["UI_Attr",        "@Char/人类"],    # 2 中上：角色属性 / buff
	["UI_Interaction", "@Char/人类"],    # 3 右上：角色交互
	["UI_Skill",       "@Char/人类"],    # 4 左下：角色技能
	["UI_Shortcut",    "@Char/SYS"],     # 5 中下：系统快捷
	["UI_Archetype",   "@Char/人类"],    # 6 右下：角色原型
]

## 2 行 3 列的二维矩阵：6 个元素各占一格。
const MATRIX: Array[Array] = [[1, 2, 3], [4, 5, 6]]

## 格子之间的间距（矩阵的 `gap`）。
const GAP := 6

## 每格"**一栏文字最多多宽**"（`max_chars`，字符数，中文算 2）——按格子宽反推：
##   3/4 屏（1920×1080 时 = 1440）÷ 3 列 ≈ 465px，扣掉：格子底图圆角边距 16 + 格子内边距 8
##   （`margin: 4` 四边）+ 格内滚动条 8 + 每个折叠段自己的底图圆角 16 + 段内边距 16 ⇒ 约 401px；
##   一个字符 ≈ 10px（等宽字体 20 号，见 `UIBase._half_width` 是**量**出来的）⇒ 40。
##   （底图圆角照留——用户要求"圆角半框要留"——所以每层面板都要从宽度里扣它那一圈，见
##   `UI_Panel._apply_background`；不收窄字数的话内容 min 超过格宽，文字溢出右邻格。）
## **为什么非写不可**：不写就用全局默认（`SysCfg.ui_view_chars` = 48 ⇒ 480px）> 401px，
## 长行会**宽过格子、右边被裁掉一块**。宁可窄一点，也别把字切掉。
## 屏幕更大 / 想更宽：调这个数（它是"一栏"这个概念的宽度，与 `SysCfg.ui_view_chars` 同一个意思）。
const CELL_CHARS := 40

## 占屏幕的比例（宽, 高）：3/4（1920×1080 ⇒ 1440×810；2560×1440 ⇒ 1920×1080）。
const RATIO := [0.75, 0.75]


## 由上面那几张表生成这一个预设——**看板的形状只有这一处**。
static func _values() -> Array[Array]:
	var kids: Array = []
	for i in CELLS.size():
		var cell: Array = CELLS[i]
		var cls: String = str(cell[0])
		# `grid` = 矩阵里的编号（占哪一格）；`char` = 默认看谁；`max_chars` = 这一格"一栏"多宽（见 CELL_CHARS）
		# `margin` = 4：格内元素离底图边 4px（共 8px 边距）；底图圆角边距（slice 16px）照留，
		# 内容宽度靠 CELL_CHARS 收窄装进"格宽 - 16 - 8"（见 UI_Panel._apply_background）
		kids.append([cls.substr(3), cls, {"char": cell[1], "grid": i + 1, "max_chars": CELL_CHARS, "margin": 4}])
	return [["RoleData", "UI_Panel", {
		"size_ratio": RATIO,                          # 尺寸 = 屏幕 × 3/4（跟分辨率走，见 UIBase._config_size）
		"open_at": Enums.OpenAt.CENTER,               # 开在屏幕正中
		"gap": GAP,
		"matrix": MATRIX,
		"events": [QName.UI_event_pointer2_menu],     # 右键 → 管理菜单（里面有"关闭"）
		# 头部两项（可折叠标题、关闭图标）+ 6 个格子：**标题写在 `grid` 子元素之前 ⇒ 排在网格上方**
		# （网格区占剩下高度，见 UI_Panel._grid_box）；关闭图标是 free ⇒ 挂叠加层，钉在右上角。
		"children": [
			UIInteract_Fold.title_item("角色数据", false, SysCfg.ui_view_chars),
			UIPreset_Basic.close_item(),
		] + kids,
	}]]


var values: Array[Array] = _values()
