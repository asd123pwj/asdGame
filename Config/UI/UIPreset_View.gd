class_name UIPreset_View
extends ConfigBase

""" ---------- 角色数据看板（6 个一览摆在一块面板里） ----------
一块面板 = **屏幕的 3/4**（尺寸在本预设里自己算，见 `_panel_size()`；开在屏幕正中），
标题下面按 **2 行 3 列**的二维矩阵分成 6 格，六个一览各占一格：

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
  · **尺寸按屏幕比例、在本预设里自己算**（`_panel_size()` = `UISys.screen_size() × RATIO`）：1920×1080 上
    就是 1440×810，换 2560×1440 自动变 1920×1080——"占屏幕多少"这件事不跟着分辨率改数字
    （框架没有"比例尺寸"配置项，见 `_panel_size` 的说明）；
  · **窗口的底图是竹框**（`WINDOW_BACKGROUND`，用户画的 64×64、四角 16×16 ⇒ `background_slice: 16` +
    `background_stretch: "tile"`）：不写 `background` 就用全局默认那张圆角方块，这里显式点成竹框
    ——"一个窗口长什么样"只属于这个预设；**换底图那圈边距也变，`CELL_CHARS` 要跟着重算**；
  · **每一格（6 个一览）的底图是卷轴**（`CELL_BACKGROUND`，64×64、四角 16×16 ⇒ slice 16 + 平铺，
    与看板竹框同一套规格）：不写会落到全局默认那张圆角方块 ⇒ 显式点成卷轴——"一栏长什么样"属于这些一览；
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
##   3/4 屏（1920×1080 时 = 1440）÷ 3 列 ≈ 465px，扣掉：**看板竹框的四角 16（一圈 32，摊到每列约 11）**
##   + 格子底图圆角边距 16 + 格子内边距 8（`margin: 4` 四边）+ 格内滚动条 **12**（`SysCfg.ui_scroll_side * 2`）
##   + 每个折叠段自己的底图圆角 16 + 段内边距 16 ⇒ 约 411px；
##   一个字符 ≈ 10.8px（等宽字体 20 号，见 `UIBase._half_width` 是**量**出来的）⇒ 38。
##   （底图圆角照留——用户要求"圆角半框要留"——所以每层面板都要从宽度里扣它那一圈，见
##   `UI_Panel._apply_background`；不收窄字数的话内容 min 超过格宽，文字溢出右邻格。）
## **为什么留余量**：实测 40 字符 = 432px 会把格内视口撑满（余 0），39 时滚条一换宽（8→12）也只剩 2px
## ——所以收到 38，留约 13px；哪天多出几像素（换个字、改个字号、条再宽一点）也不会撑出格子。
## **为什么非写不可**：不写就用全局默认（`SysCfg.ui_view_chars` = 48 ⇒ 480px）> 411px，
## 长行会**宽过格子、右边被裁掉一块**。宁可窄一点，也别把字切掉。
## 屏幕更大 / 想更宽：调这个数（它是"一栏"这个概念的宽度，与 `SysCfg.ui_view_chars` 同一个意思）。
const CELL_CHARS := 38

## 占屏幕的比例（宽, 高）：3/4（1920×1080 ⇒ 1440×810；2560×1440 ⇒ 1920×1080）。
## **尺寸在预设里自己算**（见 `_panel_size`），不再是框架的配置项——框架不必知道"尺寸从哪来"。
const RATIO := Vector2(0.75, 0.75)

## 看板**窗口自己的底图**（竹框，64×64）：不写 `background` 就用全局默认那张圆角方块
## （`SysCfg.ui_background`），这里显式换成竹框——"角色窗口长这样"只属于本预设。
## 用 `UI_Bamboo_Empty.png`（**空框**；与 `UI_Bamboo_Panel.png` 同一张画）：窗口的底只要"一个空框"，
## 不必为大窗口再画一张大的——九宫格平铺本来就够，图越小越省。
## **边距 / 中段填充不在这写**：走 `UIPreset_Basic.bg()` 的默认值（竹图那套：四角 16 + 平铺。
## 这批图都是 64×64、四角 16，中段带竹节 ⇒ 只能平铺，拉伸会按面板尺寸拉成宽暗带）。
const WINDOW_BACKGROUND := "res://Material/Texture/UI/UI_Bamboo_Empty.png"

## **每一格（6 个一览）自己的底图**（卷轴，64×64）：不写 `background` 会用全局默认那张圆角方块
## （`SysCfg.ui_background`），这里显式换成卷轴——"一栏长什么样"属于这些一览（区别于看板窗口的竹框）。
## 规格同上（`UIPreset_Basic.bg()` 的默认：四角 16 + 平铺）。注意 `UIBase._make_background` 的四边边距是
## **同一个数**（`set_texture_margin_all`）：上下端帽与左右细边都按 16 切——与 `CELL_CHARS` 里
## "格子底图圆角边距 16"那条对得上（那条本就是按 16 推的）。
const CELL_BACKGROUND := "res://Material/Texture/UI/UI_Bamboo_ScrollPanel.png"


## 看板尺寸 = 屏幕 × RATIO（像素）。
## **为什么自己算**：以前有个框架级配置项 `size_ratio`（写比例、由 `UIBase._config_size` 换算），
## 已删——"占屏幕多少"只有这一处在用，写在用它的地方就够了；而尺寸的"来路"框架本来就不该管
## （改尺寸 / 等比缩放手柄都已就位，尺寸定死之后由手柄改）。
## `UISys.screen_size()` 拿不到视口时（如静态初始化阶段）会退回项目基准分辨率，算出来照样对。
static func _panel_size() -> Array:
	var px: Vector2 = (UISys.screen_size() * RATIO).floor()
	return [px.x, px.y]


## 由上面那几张表生成这一个预设——**看板的形状只有这一处**。
static func _values() -> Array[Array]:
	var kids: Array = []
	for i in CELLS.size():
		var cell: Array = CELLS[i]
		var cls: String = str(cell[0])
		# `grid` = 矩阵里的编号（占哪一格）；`char` = 默认看谁；`max_chars` = 这一格"一栏"多宽（见 CELL_CHARS）
		# `margin` = 4：格内元素离底图边 4px（共 8px 边距）；底图圆角边距（slice 16px）照留，
		# 内容宽度靠 CELL_CHARS 收窄装进"格宽 - 16 - 8"（见 UI_Panel._apply_background）
		# 底图（卷轴，见 CELL_BACKGROUND）走通用三键构造器：不写会落到全局默认那张圆角方块。
		var cfg: Dictionary = {"char": cell[1], "grid": i + 1, "max_chars": CELL_CHARS, "margin": 4}
		cfg.merge(UIPreset_Basic.bg(CELL_BACKGROUND))
		kids.append([cls.substr(3), cls, cfg])
	var panel: Dictionary = {
		"size": _panel_size(),                        # 尺寸 = 屏幕 × 3/4（在本预设里算，见 _panel_size）
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
	}
	# 本窗口的底 = 竹框（不是全局默认那张圆角方块）；三键（图 + 边距 + 平铺）走通用构造器。
	panel.merge(UIPreset_Basic.bg(WINDOW_BACKGROUND))
	return [["RoleData", "UI_Panel", panel]]


var values: Array[Array] = _values()
