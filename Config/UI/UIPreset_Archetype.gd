class_name UIPreset_Archetype
extends ConfigBase

""" ---------- 角色原型一览 ----------
 ▾ 角色原型                          ← 头部（可折叠标题：点它整块收起 / 展开）
 [关闭]                              ← 一条普通事件指令（UIInteract.close）
 Body(UI_Archetype)                  ← **内容是一个"原型一览"元素**（Script/UI/UI/UI_Archetype.gd）
   角色原型：@Char/人类  [刷新]       ← 元素铺的抬头（看的是哪个角色）
   原型：人类（只在角色**初始化时**装配一次；下面是合并 packages 之后的清单）

   ▾ buffs（3 项）                    ← 一个字段一段；**默认摊开**，空字段收着
       　· Nourish
       　· Injured
       　· Rebirth
   ▾ statuses（12 项）
       　· AlwaysSatisfied@SYS
       …
   ▾ packages（1 项）                 ← 合并了哪几个包（这些包的东西已经并进上面各段了）

**这个一览不实时**（原型只在 `Character._init_from_archetype` 那一刻生效，之后改原型不会回头动角色）
⇒ 元素不订任何消息，只在铺 / 点 `[刷新]` 时读一次 `Archetype.get_(char.archetype_type)`。
换人看：`UIInteract.open(preset_name="Archetype", content_cmd="@Char/兔子")` 再点 `[刷新]`。

**注意清单是"合并后"的**：`Archetype.get_` 第一次取时会把 `packages` 里各原型的字段并进来
（buffs 不去重、其余去重）⇒ 看到的 `statuses` / `skills` 那些已经是合并结果，`packages` 段只是记录。
"""


## 独立 UI：`open(preset_name="Archetype")` 就开在配置声明的这个位置。
## 摆在第一排那几个一览（状态 / 属性 / 交互 / 技能）**下面**一行，不跟它们挤。
var values: Array[Array] = [
    ["Archetype", "UI_Panel", {
        "position": [40, 600],
        # **不写 size**：宽度跟着内容走（写死宽会裁掉长文案）
        "scroll": [0, 520],                          # 宽不限（0 = 跟着内容）、高到 520 就进滚动
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_mouseLeft_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("角色原型", false, SysCfg.ui_view_chars),
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [[QName.mouseLeft, "UIInteract.close(@self.parent)"]],
            }],
            # 内容：原型一览元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Archetype", {
                "char": "@Char/人类",                # 默认看 char_A（test.gd 里 spawn("人类","player") 那个）
            }],
        ],
    }],
]
