class_name UIPreset_EditorText
extends ConfigBase

""" ---------- 编辑器模板：文本 / 数组 ----------
UI 编辑器里"一行"长什么样，就是这些模板说了算（见 Script/UI/UI/UI_Editor.gd 的 kinds / special）。
**这是一份可以随便改的模板**：觉得不好用，照着它写一个新预设，再把名字填进元素的 `kinds`
（或某个键的 `special`）即可——元素那边一行代码都不用动：

    ["Body", "UI_Editor", {"kinds": {"text": "我自己的文本模板"}}]

元素交给模板的三个配置键（模板的提交指令可以自己用）：
    content  当前值（显示用）；source  写回的路径；target  被编辑 UI 的登记名（纯字典时为空）
本模板**没写 events** ⇒ 元素会补上默认那套（点进编辑 + 回车提交写回 + 重应用 + 刷新）。
"""


## 多行输入框：长文本 / 数组（如 [30, 30]）一眼看全，回车提交（输入框的规矩见 UI_Input）。
var values: Array[Array] = [
    ["UIEditorText", "UI_Input", {
        "multiline": true,
        "max_height": 160,                         # 太高就框内滚动，不把编辑器顶长
        "size": [260, 0],                          # 宽度定死，编辑框才看得出里面有什么
    }],
]
