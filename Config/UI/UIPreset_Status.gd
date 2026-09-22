class_name UIPreset_Status
extends ConfigBase

""" ---------- 角色状态一览 ----------
 ▾ 角色状态                          ← 头部（可折叠标题：点它整块收起 / 展开）
 [关闭]                              ← 一条普通事件指令（UIInteract.close）
 Body(UI_Status)                     ← **内容是一个"状态一览"元素**（Script/UI/UI/UI_Status.gd）
   角色状态：@Char/SYS  [刷新]（重读 + 重订）   ← 元素铺的抬头（看的是哪个角色）
   ▸ Tick（✔ 满足｜依赖 1 条）       每个状态一段，**默认收起**；标题上的 ✔/✘ 是**实时**的
       满足：✔
       最近消息：（无）
       auto_reset=false   match_any=false   with_detect=false
       【时间 依赖：1 条】
         Tick  Advance   → ✔ 触发

看哪个角色由 Body 的 `char` 决定（默认**系统角色 SYS**，改这一行就换人）；
开的时候也能临时指定（`content_cmd` 优先于 `char`，**开完点一下 `[刷新]` 生效**）：
  UIInteract.open(preset_name="Status")
  UIInteract.open(preset_name="Status", content_cmd="@Char/人类")   # 再点 [刷新]
  # 已经开着的话，`open` 会把新配置写到外壳上（独立 UI 是复用同一份的），[刷新] 一读就到手。

**实时与监听**：元素订阅被看角色**每个状态**的 satisfied / unsatisfied，收到就只重铺那一段。
**开着就一直听**（收起的段标题上也写着 ✔/✘，它照样得是实时值），**关掉就全退**（不留订阅挂在消息系统里），
**重开**由 `UIBase.on_shown` 那一声自动订回来（open 新建 / 复用两条路都会通知）。
见 Script/UI/UI/UI_Status.gd 的文件头。

**为什么内容交给元素而不是写在这儿**：一个角色装了哪些状态、每个状态依赖什么、现在触发成什么样，
全是**运行期**的事（状态是静态预设、触发真值按角色存，见 Character/Status/Status.md 的"角色状态一览"）。
所以外壳只是"标题 + 一个关闭按钮 + 一块内容"，内容长什么样与它无关。
"""


## 独立 UI（不挂别的 UI 下面）：`open(preset_name="Status")` 就开在配置声明的这个位置。
## `scroll` = [上限宽, 上限高]：宽定死 360（长依赖名在框里换行），高最多 460——
## 状态再多也只在框内滚动，不把面板顶出屏幕（见 UI_Panel 的文件头）。
## `events`：右键开它自己的菜单（可选）＋ 按住拖动面板（和键盘 UI 那种面板一样）。
var values: Array[Array] = [
    ["Status", "UI_Panel", {
        "position": [40, 40],
        "size": [360, 0],                            # 宽固定、高随内容（上限由 scroll 收口）
        "scroll": [360, 460],
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_mouseLeft_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("角色状态"),
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [[QName.mouseLeft, "UIInteract.close(@self.parent)"]],
            }],
            # 内容：状态一览元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Status", {
                "char": "@Char/SYS",                 # 默认看系统角色；换人只改这一行
            }],
        ],
    }],
]
