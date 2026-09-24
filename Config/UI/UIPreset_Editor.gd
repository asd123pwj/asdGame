class_name UIPreset_Editor
extends ConfigBase

""" ---------- UI 编辑器（外壳） ----------
一个"能编辑某个 UI 全部内容"的菜单。**这里只有外壳**：

  高级管理：MiniHUD          ← Head：开的时候由编辑器元素写"正在编辑谁"
  ✕  [重建：重读子UI]    ← 两条普通事件指令
  Body(UI_Editor)            ← **内容是一个字典型编辑器元素**（Script/UI/UI/UI_Editor.gd）
    ▾ Config（5 项）            每项一行：小字键名 + 值输入框（回车提交）
        position   [30, 30]
    ▸ 子UI：Title（UI_Label）   每个子UI一段，**默认收起**，展开哪段才铺那段

**内容为什么不是写在这儿的 children**：要铺的东西（有几个子UI、有哪些 config 键）是**运行期**才知道的。
现在这层"运行期结构"完全交给 UI_Editor 元素按配置处理：
  - `source` 指哪本字典（Body 不写 ⇒ 用 host 的 config）；
  - `special` 给个别键指定处理方式（`"children": "ui"` ⇒ 每个子UI一段、递归它自己的编辑器）；
  - `kinds` 指定"某种值用哪个元素渲染"（默认见 UI_Editor.DEFAULT_KINDS）。
所以外壳只是"标题 + 两个按钮 + 一块内容"，内容长什么样与它无关——加"列表型 / 数值型编辑器"也不用改这里。

**打开它没有专用指令**：`UIInteract.open(@host, "Editor", @host, host=@host)`
（内容由元素在**登记完成**时自己铺；"[重建]"是内容里的第一行，一行 `@self.parent.rebuild()`。）
"""


## UI 编辑器的外壳（内容由 Body 那个 UI_Editor 元素自己铺）。
## `scroll` = [上限宽, 上限高]：宽定死 340（长命令在输入框里换行，不横向撑），高最多 460
## ——内容再多也只在框内滚动，而不是把菜单顶出屏幕（见 UI_Panel 的文件头）。
## `events`：右键**开它自己的菜单**（`UIEditorMenu`），那条指令把 host 写成 `@self` = 编辑器自己
## ⇒ 菜单项里的 `@host` 就是**这个编辑器**（不是它管理的那个 UI）。于是"在编辑器里开编辑器"编辑的是
## **编辑器自己**，与"被编辑 UI 的编辑器"名字自然不同（`…/UIEditor` vs `…/UIEditor/UIEditor`），不会撞车复用。
var values: Array[Array] = [
    ["Editor", "UI_Panel", {
        "scroll": [340, 460],
        "free": true,                              # 自由定位：挂到被编辑 UI 的叠加层，位置不被布局改
        "open_at": Enums.OpenAt.POINTER,           # 开在指针处（右键 → UI 编辑器）
        "events": [QName.UI_event_pointer1_drag,
                   QName.UI_event_pointer2_menu],
        "children": [
            # 头部 = **可折叠标题**（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）。
            # 用的是折叠交互那套片段，所以标题长得和其它可折叠分组一样。
            UIInteract_Fold.title_item("编辑器"),
            UIPreset_Basic.close_item(),   # 图标式关闭（右上角）：和 CloseButton 预设同一张图 / 同一套指令
            # 内容：字典型编辑器元素。铺什么、怎么处理都在它的配置里——
            # source 不写 = 用 host 的 config；special 给个别键单独指定模板。
            ["Body", "UI_Editor", {
                # 子UI数组：每项一段、**默认收起**（展开才建里面的编辑器）。
                # 模板写法：`"预设名"`（换个模板最省事，见 Config/UI/UIPreset_Editor*.gd）
                # 或 `[元素类名, 配置片段]`；元素类是 UI_Editor = 递归一个编辑器。
                "special": {"children": ["UI_Editor", {"collapsed": true}]},
            }],
        ],
    }],
]
