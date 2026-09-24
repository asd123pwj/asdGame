class_name UIPreset_Skill
extends ConfigBase

""" ---------- 角色技能一览 ----------
 ▾ 角色技能                          ← 头部（可折叠标题：点它整块收起 / 展开）
 ✕                              ← 右上角图标关闭（UIPreset_Basic.close_item）
 Body(UI_Skill)                      ← **内容是一个"技能一览"元素**（Script/UI/UI/UI_Skill.gd）
   角色技能：@Char/人类  [刷新]       ← 元素铺的抬头（看的是哪个角色）
   共 6 条技能（标题上的 ✔/✘、「在队列」与「最近执行」是实时的）

   ▸ Walk Right（Skill_Walk ｜ 依赖：Right@SYS ✔ ｜ 在队列 ｜ 最近执行 16:48:13）
       实现类：Skill_Walk
       依赖状态：Right@SYS　→　✔ 满足　（Right@SYS → Char/SYS）
       队列：**在**（逐帧执行中，参数：[300]）                ← 队列里那份参数才是真的在用的
       加装：16:48:12（元年正月初一 子时）                     ← 流水三行（同交互一览；都到秒）
       移除：（还没）
       执行：16:48:13（元年正月初一 子时）                     ← 每物理帧都在跑 ⇒ 流水那边限流成每秒一笔
       参数：[300]（技能的参数是数组，一行说清）

看哪个角色由 Body 的 `char` 决定（默认 **char_A**），换人写 `content_cmd="@Char/兔子"` 再点 `[刷新]`：
  UIInteract.open(preset_name="Skill")
  UIInteract.open(preset_name="Skill", content_cmd="@Char/兔子")

**依赖状态可以写 `状态名@identity`**（技能表里就是这么写的：`Right@SYS`、`AlwaysSatisfied@SYS`）：
进 / 出队看的是**解析到的那个角色**的该状态，段里也会把"解析到了谁"写出来。

**实时与监听**：订"每条技能依赖的那个状态"（与进出队看的是同一个节点）+ "任意技能"的通配
（`Msg.listen_skill_any_changed`：增 / 删 ⇒ 整块重铺；**执行 ⇒ 只就地换标题那一行**）。
技能每物理帧都在执行，而"执行"那条消息**照发不省**（限流只做在流水那边：
`SysCfg.history_window` 秒内超过 `history_window_max` 次 ⇒ 之后每秒只记一次 ⇒ 标题上那句"最近执行"
最多每秒变一次，界面也就每秒最多画一次）；
**开着才听、关掉全退、重开订回**（骨架见 UI_View，细节见 UI_Skill 的文件头）。

**为什么内容交给元素而不是写在这儿**：一个角色装了哪些技能、每条依赖哪个状态、现在在不在跑，
都是**运行期**的事（`Character.skills`）。外壳只是"标题 + 关闭 + 一块内容"。
"""


## 独立 UI：`open(preset_name="Skill")` 就开在配置声明的这个位置。
## 摆在另外几个一览（状态 [40,40]、属性 [420,40]、交互 [820,40]）右边，不叠。
var values: Array[Array] = [
    ["Skill", "UI_Panel", {
        "position": [1240, 40],
        # **不写 size**：宽度跟着内容走（写死宽会裁掉长文案）
        "scroll": [0, 520],                          # 宽不限（0 = 跟着内容）、高到 520 就进滚动
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_pointer1_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("角色技能", false, SysCfg.ui_view_chars),
            UIPreset_Basic.close_item(),   # 图标式关闭（右上角）：和 CloseButton 预设同一张图 / 同一套指令
            # 内容：技能一览元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Skill", {
                "char": "@Char/人类",                # 默认看 char_A（test.gd 里 spawn("人类","player") 那个）
            }],
        ],
    }],
]
