class_name UIPreset_MetaTest
extends ConfigBase

"""
---------- 富文本链接测试（meta 的各种用法都在这一个窗口里） ----------
Text(UI_Label，内核是 RichTextLabel)：**三行文本、只显示两行**（size 高度写死 = 显示区定死）
⇒ 出滚动条——测"滚动时显示是否正确"。
文字里的每一段都用 `[url=meta]` 标出来，**meta = 事件名 + 冒号 + 一条现成指令**（见 UIInteract_Meta）：
  拖动 / 关闭   按下时执行（就是 QName 里那两条常用绑定：UI_event_pointer1_drag_host / _close_host）
  折叠          按下时执行（本窗自己的一条，见下面 FOLD_STATUS）
  浮窗一 / 浮窗二 悬停时执行（**各开一个预设**：通用 "Tip" 与本地 "Tip2"，用来测多浮窗）
正文里每段链接只填一个 `%s`：绑定写成"事件 + 指令"的**一整对**（常用那几对在 QName 里），
用 `UIInteract_Meta.as_meta(那一对)` 拼成 meta 的形状——`QName.pointer1_hold, CMD_DRAG` 这种
"触发状态 + 命令"本来就是一起的，所以整对放在一处，不必在正文里散着写。
浮窗的规矩（都由 UIInteract_Meta 管）：同时只留一扇；指针不在"有说明的那段字"上就收；
**指针移进浮窗自己身上不算离开**；指针移出整个元素时全收。
"""

## 本窗自己的三条绑定（"事件 + 指令"的一整对；拖动 / 关闭用 QName 里那两条常用的）。
## 用 `static var` 而不是 `const`：里面引用了 QName 的 static var（const 不能引用它们）。
static var FOLD_STATUS := [QName.pointer1_hold, 'UIInteract.toggle_fold(@UI/Status)']
static var TIP_ONE := [QName.pointer_move, 'UIInteract.open(@self, "Tip", @self, content="地图「草药田」：3 块地，产量 2/天，可采集")']
static var TIP_TWO := [QName.pointer_move, 'UIInteract.open(@self, "Tip2", @self, content="第二个浮窗：这段字有它自己的说明")']

var values: Array[Array] = [
    ["MetaTest", "UI_Panel", {
        "position": [620, 600],                    # 摆在属性 / 交互一览下面那排空当里
        "scroll": [0, 520],                        # 宽随内容、高到 520 进滚动（窗口自己的）
        "free": true,                              # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_pointer1_drag],
        "children": [
            UIPreset_Basic.close_item(),           # 右上角图标关闭（和其它窗口同一套）
            # 富文本正文：size 高度写死 ⇒ 只显示两行，多出来的进去滚动
            ["Text", "UI_Label", {
                "size": [380, 70],
                # 每一行各带自己的 `% []`：**参数就写在用到它的那行旁边**，不必回头数第几个。
                # （`%` 比 `+` 先算，所以 `"…" + "…%s…" % [x]` 正是"先填这一行，再接到前面"。）
                "content": (
                    "（一）这三行文本只显示两行，多出来的进去滚动——测滚动条显示对不对。\n"
                    + "（二）点 [url=%s]拖动[/url] 按住可拖这个窗口；点 [url=%s]关闭[/url] 关掉它。\n"
                        % [UIInteract_Meta.as_meta(QName.UI_event_pointer1_drag_host),
                           UIInteract_Meta.as_meta(QName.UI_event_pointer1_close_host)]
                    + "（三）点 [url=%s]折叠[/url] 把状态一览收起来。\n"
                        % [UIInteract_Meta.as_meta(FOLD_STATUS)]
                    + "（四）悬停这两段字各开一扇浮窗（测换一扇时上一扇会不会关）：[url=%s]浮窗一[/url] / [url=%s]浮窗二[/url]；移到这行字别的部分不弹。"
                        % [UIInteract_Meta.as_meta(TIP_ONE), UIInteract_Meta.as_meta(TIP_TWO)]
                ),
                # 三条事件都指同一个入口：它自己按 meta 的前缀认这次该执行哪条（见 UIInteract_Meta）。
                "events": [
                    [QName.pointer1_hold, 'UIInteract.meta_event(@self)'],
                    [QName.pointer_move, 'UIInteract.meta_event(@self)'],
                    [QName.pointer_exit, 'UIInteract.meta_event(@self)'],   # 移出元素 ⇒ 把浮窗全收掉
                ],
            }],
        ],
    }],
    # 第二扇浮窗（"浮窗二"开它）：用来测"换一扇时上一扇会不会自动关"。
    # **第一扇不在这里**——那是通用的 "Tip" 预设（见 UIPreset_Basic，关闭/缩放按钮也用它）；
    # 这里只留一个同形状的第二扇，好让"两扇不同的窗"这个场景测得到。
    ["Tip2", "UI_Panel", {
        "size": [0, 0],
        "free": true,
        "open_at": Enums.OpenAt.ANCHOR_TOP_RIGHT,  # 开在锚点（文字元素）右上角外
        "children": [
            # 正文读**外壳的** content（`open(..., content="…")` 合并进来的就是它）：
            # content_cmd 里的 `@self` = 写这条指令的元素（这里就是本元素），见 UIBase.refresh。
            ["Text", "UI_Label", {
                "content": "（提示二）",                 # 字面值 = 没带内容进来时的兜底
                "content_cmd": "@self.parent.config.content",
                "max_chars": 40,
            }],
        ],
    }],
]
