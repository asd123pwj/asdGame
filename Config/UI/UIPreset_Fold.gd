class_name UIPreset_Fold
extends ConfigBase

""" ---------- "长内容 / 可收回"演示 ----------
要解决的问题：一块 UI 的配置太长（菜单项、配置项一大串）时，它会顶出屏幕下边
（子 UI 的"管理菜单"就是这种情况）。解法是**收回（隐藏）而不是关闭**：
整块能收成一个标题栏，里面每一段也能各自收。

用的是已有机制的组合，没有专门元素：
  - "收 / 展"是交互指令 `UIInteract.fold(目标, true/false)` / `UIInteract.toggle_fold(目标)`
    （实现见 Script/UI/Interact/UIInteract_Fold.gd，UIBase 里**没有**折叠代码）；
  - 一行"可折叠标题"就够了：`make_fold_title("标题")`（本文件的 static 片段，见下）——
    它自己既是标题也是收回按键：`▾ 标题` / `▸ 标题` 两套文字对调 + 点它收起/展开所在的分组；
  - 两个配置键：父元素上 `collapsed`（收起态）；**子元素自己**标 `collapse_keep = true` 表示
    "收起时留着我"（默认不标 = 跟着收起）——所以"谁留下"写在自己身上，父元素不维护名字清单；
  - 收起 = 其余子元素 hide()（**不销毁实例**），不可见的子元素不参与容器布局 ⇒
    容器按内容收缩 ⇒ size 里为 0 的那一维（"宽固定、高随内容"）自己就变短，不再占屏幕。

套娃：FoldDemo（整块）→ SecA/SecB/SecC（每段各自可收）。收回整块时全藏；
展开整块后，每段仍保持它自己收起/展开的状态（状态各自记在各自的 config 里）。

要加到真实菜单上：把想收的那一串菜单项包进一个 `UI_Panel`，**第一行放 make_fold_title**，
其余照旧（外层列表不用改）。别的预设想用这个标题也一样：
  children.append(UIPreset_Fold.make_fold_title("一段很长的配置"))
"""


## **可折叠标题**（可复用片段）：返回一条 `UI_Label` 配置——它自己就是标题 + 收回按键。
## 点它 ⇒ `UIInteract.toggle_fold(self.parent)` 收起/展开它**所在的那个分组**，同时把箭头对调
## （`content` / `content_2` 两套文字，见 UI.md 的"开关式按钮"：同一个元素写两套配置、点一下换一套）。
## `collapse_keep: true` 是**它自己**声明"收起时留着我"——不标的话收起来后就再也点不回来了。
## 想换样子（标题带底、或者另放一个 `[+]`/`[-]` 按钮）照抄这段改 `content` / `events` 即可。
static func make_fold_title(title: String) -> Array:
    return ["Title", "UI_Label", {
        "content": "▾ %s" % title,
        "content_2": "▸ %s" % title,
        "collapse_keep": true,
        "events": [[QName.mouseLeft,
            'UIInteract.toggle_fold(self.parent)'
            + '\vUtils.swap("self.config.content", "self.config.content_2")'
            + '\vself.refresh("content")']],
    }]


## 一段"很长"的分组（模拟菜单里的一大串项）：**第一行是可折叠标题**，后面 rows 行内容。
## 标题收起时那段就只剩标题一行（内容行没标 collapse_keep ⇒ 跟着藏）。
static func _section(name_: String, title: String, rows: int) -> Array:
    var children: Array = [make_fold_title(title)]
    for i in rows:
        children.append(["Row%d" % i, "UI_Label", {"content": "第 %d 项：很长很长的一行内容" % (i + 1)}])
    return [name_, "UI_Panel", {"size": [250, 0], "children": children}]


var values: Array[Array] = [
    ["FoldDemo", "UI_Panel", {
        "position": [700, 30],
        "size": [270, 0],                            # 宽固定、高随内容 ⇒ 收起后自己变短
        "children": [
            make_fold_title("折叠演示"),              # 整块的标题（点它整块收起 / 展开）
            _section("SecA", "一段很长的配置", 8),
            _section("SecB", "又一段很长的配置", 8),
            _section("SecC", "第三段很长的配置", 8),
        ],
    }],
]
