class_name UIPreset_FPS
extends ConfigBase

""" ---------- FPS 显示 ----------
一小块显示当前帧率的文字，摆在屏幕左上角（位置写死在本文件）：

  ┌──────────┐
  │ FPS 60   │
  └──────────┘

- **值从哪来**：文字那条 `content_cmd` = `UIPreset_FPS.text()`（`Engine.get_frames_per_second()`，
  引擎给的是**滚动平均**，本来就够稳，不必自己算差）。
- **谁每帧让它重算**：SYS 角色上那条 **Tick 快捷**（`UIPreset_FPS.tick`，见 Archetype_System）——
  "每帧要做的事"在这个项目里就是"**状态 + 快捷**"这一条路（`QName.tick` 是逐帧满足的状态，
  由 TimeSys 每帧推进）。**那扇 UI 没开着时它第一句就 return**（按登记名查不到），所以常驻也不花什么。
- **只在"取整后变了"时才真刷**：帧率每帧都会动一点，不判一下就是每帧重排版
  （同 `UI_View._refresh_section_title` 那条理由）。
- **开关**：按 **F3**（`QName.key_f3` 那条状态 + 一条 `UIInteract.toggle(preset_name="FPS")`）；
  想用指令开也行：`UIInteract.open(preset_name="FPS")`。
- **底图不写**：面板不写 `background` 就自带**全项目默认那张**（浅色圆角图）——文字压在浅底上看得清；
  想要"没有框"就显式写 `"background": ""`（那是"明确不要底"的意思）。
"""
## 摆在哪（屏幕像素）：独立 UI 的绝对位置，左上角留一点余量。
const POSITION := Vector2(8, 8)
## 一栏文字最多多宽（**字符数**，中文算 2，见 UI_Label 的 max_chars）：
## 写死是为了**宽度不跳**——帧率位数一变，框别跟着伸缩。
const CHARS := 12


## 那行字：`FPS 60`。**每次 refresh 重算一次**（被谁用：本预设里 `Text` 那条 `content_cmd`）。
static func text() -> String:
	return "FPS %d" % Engine.get_frames_per_second()


## **每帧那条 Tick 快捷的落点**（见 Archetype_System 里 `[QName.tick, QName.tick, 'UIPreset_FPS.tick()']`）：
## 把 FPS 那行字刷成当前值。
## 值**不在这儿拼**——"内容从哪来"只有 `content_cmd` 那一处（`refresh` 会重算并写回 `config["content"]`），
## 这里只负责两件事：**要不要刷**（没开那扇 UI / 取整没变 ⇒ 什么都不做）与**刷一下**。
static func tick() -> void:
	var text_ui: UIBase = UISys.get_ui("UI/FPS/Text")
	if text_ui == null:
		return                                  # 那扇 UI 没开着：直接走（这条快捷常驻也几乎零成本）
	if str(text_ui.config.get("content", "")) == text():
		return                                  # 取整后没变：不重排版
	text_ui.refresh("content")


var values: Array[Array] = [
    # FPS 这块：面板（**不写 background** ⇒ 全项目默认那张浅色圆角底图）+ 一行文字。
    # 尺寸两维写 0 = 随内容：面板就"一行字 + 内边距"那么大。
    ["FPS", "UI_Panel", {
        "position": [POSITION.x, POSITION.y],
        "size": [0, 0],
        "open_at": Enums.OpenAt.CONFIG,           # 摆在 config 里写的那个位置（固定点，不跟指针）
        "children": [
            # 文字：内容走 `content_cmd`（每次刷新现算一次帧率）；`content` 只是"还没刷过"时的兜底
            ["Text", "UI_Label", {
                "content": "FPS --",
                "content_cmd": "UIPreset_FPS.text()",
                "max_chars": CHARS,
            }],
        ],
    }],
]
