class_name UIPreset_Basic
extends ConfigBase

"""
name: String
ui_name: String
config: Dictionary
"""
var values: Array[Array] = [
    ["MiniHUD", "UI_Panel", {
        "position": [30, 30], "size": [320, 220],
        "draggable": true, "closeable": true, "scalable": true, "submittable": true,
    }],
]
