class_name UIPreset_Basic
extends ConfigBase

"""
UI 最小原型配置（values 每项 = 一个完整 UI 描述）。
文档见 Script/UI/UI设计.md §3。
UI 描述字段：
  name:  UI 唯一名
  root:  根元素描述 {type, name, style, text, cmd, children}
  style: 本 UI 级显示属性（作为整树默认 style）
元素 style 支持常用显示属性：position/size/color/font_size/bg/visible 等。
"""

var values: Array[Dictionary] = [
	{
		"name": "MiniHUD",
		"style": { "font_size": 16 },
		"root": {
			"type": "Panel",
			"name": "hud",
			"style": { "position": [20, 20], "size": [300, 60] },
			"children": [
				{ "type": "Label", "name": "hp_label",
				  "text": "HP {hp}", "style": { "color": "#FF4040" } },
				{ "type": "HPBar", "name": "hpbar", "bind": "hp" },
				{ "type": "VBox",
				  "children": [
					  { "type": "Button", "name": "btn", "text": "放一个门",
					    "cmd": "MapSys.place 0 8 -5 门 2 -1 true" }
				  ]}
			]
		}
	},
]
