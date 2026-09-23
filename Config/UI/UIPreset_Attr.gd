class_name UIPreset_Attr
extends ConfigBase

""" ---------- 角色属性 / Buff 一览 ----------
 ▾ 角色属性                          ← 头部（可折叠标题：点它整块收起 / 展开）
 [关闭]                              ← 一条普通事件指令（UIInteract.close）
 Body(UI_Attr)                       ← **内容是一个"属性一览"元素**（Script/UI/UI/UI_Attr.gd）
   属性：@Char/人类  [刷新]           ← 元素铺的抬头（看的是哪个角色）
   共 4 个类别 ｜ 6 个 buff

   ▸ 生命（CUR 2 ｜ buff 2 个 ｜ 改动：Init）     每个类别一段，**默认收起**；标题是摘要
       当前值：BASE 2   CUR 2   MIN 0   MULTIPLIER 1        ← 四个值域（Enums.ValueType）
       改动前：BASE 2   CUR 2   …                          ← attributes_before（暂时没用上，但看得见）
       最近改动：谁=@Char/人类  怎么改=Init                  ← attributes_changed_by_who / _how
       参与 Buff（2 个）                                    ← buffs[类别]：**一行一个 buff**
         BASE   Nourish            +10   次数：不限           ← 值域 / 名字 / method+value / max_uses+uses[这个角色]
         MIN    人被杀就会死         =0    次数：已用 1 / 上限 2（剩 1）

看哪个角色由 Body 的 `char` 决定（默认 **char_A**：`test.gd` 里 `CharSys.spawn("人类", "player")` 那个，
注册名 `Char/人类`）；开的时候也能临时指定（`content_cmd` 优先于 `char`，**开完点一下 `[刷新]` 生效**）：
  UIInteract.open(preset_name="Attr")
  UIInteract.open(preset_name="Attr", content_cmd="@Char/兔子")   # 再点 [刷新]

**实时与监听**：订两条通配——"任何属性变化"（`AnyChanged`，payload 是类别 ⇒ 只重铺那一段）与
"任意 buff 变化"（`Msg.listen_buff_any_changed`）⇒ 运行期新加的 buff 也收得到；
**开着才听、关掉全退、重开订回**（骨架见 UI_View，细节见 UI_Attr 的文件头）。

**为什么内容交给元素而不是写在这儿**：一个角色有哪些类别、每个类别四个值域多少、
挂着哪些 buff、最近被谁改的——全是**运行期**的事（属性是懒算的）。外壳只是"标题 + 关闭 + 一块内容"。
"""


## 独立 UI：`open(preset_name="Attr")` 就开在配置声明的这个位置。
## 放在状态一览（`position [40,40]`、宽 360）右边，两份并排不叠。
var values: Array[Array] = [
    ["Attr", "UI_Panel", {
        "position": [420, 40],
        "size": [360, 0],                            # 宽固定、高随内容（上限由 scroll 收口）
        "scroll": [360, 460],
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_mouseLeft_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("角色属性"),
            ["Close", "UI_Label", {
                "content": "[关闭]",
                "events": [[QName.mouseLeft, "UIInteract.close(@self.parent)"]],
            }],
            # 内容：属性一览元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Attr", {
                "char": "@Char/人类",                # 默认看 char_A（test.gd 里 spawn("人类","player") 那个）
            }],
        ],
    }],
]
