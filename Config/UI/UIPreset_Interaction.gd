class_name UIPreset_Interaction
extends ConfigBase

""" ---------- 角色交互一览 ----------
 ▾ 角色交互                          ← 头部（可折叠标题：点它整块收起 / 展开）
 [关闭]                              ← 一条普通事件指令（UIInteract.close）
 Body(UI_Interaction)                ← **内容是一个"交互一览"元素**（Script/UI/UI/UI_Interaction.gd）
   角色交互：@Char/人类  [刷新]       ← 元素铺的抬头（看的是哪个角色）
   共 5 条交互（点一条展开看实现类 / 依赖状态 / 参数；标题上的 ✔/✘ 是实时的）

   ▸ Attack（Interaction_Attack ｜ 依赖：Detect=>Practice ✔）   每条交互一段，**默认收起**；标题是摘要
       实现类：Interaction_Attack
       依赖状态：Detect=>Practice　→　✔ 满足                    ← 依赖的状态现在满不满足（实时）
       参数（2 项）                                             ← InteractionPreset.config：一行一个键
        　attacker = Strength 的当前值
        　defender = Defense 的当前值

看哪个角色由 Body 的 `char` 决定（默认 **char_A**：`test.gd` 里 `CharSys.spawn("人类", "player")` 那个，
注册名 `Char/人类`）；开的时候也能临时指定（`content_cmd` 优先于 `char`，**开完点一下 `[刷新]` 生效**）：
  UIInteract.open(preset_name="Interaction")
  UIInteract.open(preset_name="Interaction", content_cmd="@Char/兔子")   # 再点 [刷新]

**依赖状态可以写 `状态名@identity`**（定向到"演这个位子"的那个角色）：那时段里会把"解析到了谁"也写出来
（`Detect=>Practice@player → Char/人类`）；✔/✘ 是按**解析到的那个角色**的该状态算的。

**实时与监听**：订"每条交互依赖的那个状态"（与真的触发看的是同一个节点 ⇒ ✔/✘ 当场变）
+ "任意交互"的通配（`Msg.listen_interaction_any_changed`：增 / 删 / 触发 ⇒ 整块重铺）；
**开着才听、关掉全退、重开订回**（骨架见 UI_View，细节见 UI_Interaction 的文件头）。

**为什么内容交给元素而不是写在这儿**：一个角色装了哪些交互、每条依赖哪个状态、现在满不满足，
都是**运行期**的事（`Character.interactions`）。外壳只是"标题 + 关闭 + 一块内容"。
"""


## 独立 UI：`open(preset_name="Interaction")` 就开在配置声明的这个位置。
## 摆在另外三个一览（状态 [40,40]、属性 [420,40]、快捷 [430,40]）右边，不叠。
var values: Array[Array] = [
    ["Interaction", "UI_Panel", {
        "position": [820, 40],
        "size": [400, 0],                            # 宽固定、高随内容（上限由 scroll 收口）
        "scroll": [400, 520],
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_mouseLeft_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("角色交互"),
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [[QName.mouseLeft, "UIInteract.close(@self.parent)"]],
            }],
            # 内容：交互一览元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Interaction", {
                "char": "@Char/人类",                # 默认看 char_A（test.gd 里 spawn("人类","player") 那个）
            }],
        ],
    }],
]
