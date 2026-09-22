class_name UIPreset_EditorNumber
extends ConfigBase

""" ---------- 编辑器模板：数字 / 布尔 ----------
单行输入框，窄一点（数字 / true / false 都不长）——和文本模板的差别只是"长什么样"，
换掉它就是换个模板（见 UIPreset_EditorText 的说明与 UI_Editor 的 kinds）。
"""


var values: Array[Array] = [
    ["UIEditorNumber", "UI_Input", {
        "size": [110, 0],
    }],
]
