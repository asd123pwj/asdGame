class_name UIPreset
extends PresetRegister
## UI 预设（设计见 Script/UI/UI.md）。
## 一条 UI 配置 = name(唯一名) + ui_name(实现类名) + config(显示/交互配置)。
## 按 ui_name 实例化对应 UIBase，注册进 static _we。
## create_element 同时供父元素组装子元素（config["children"]）复用。

var name: String
var ui_name: String
var config: Dictionary
var ui: UIBase

static var _we: Dictionary[String, UIPreset] = {}


func _init(name_: String, ui_name_: String, config_: Dictionary = {}) -> void:
	_we[name_] = self
	name = name_
	ui_name = ui_name_
	config = config_
	_get_ui_by_name()


static func get_(name_: String) -> UIPreset:
	return _we.get(name_)


## 按类名实例化一个 UI 元素（根 UI 与子元素共用此工厂）。
static func create_element(element_name: String, ui_name_: String, element_config: Dictionary = {}) -> UIBase:
	for cls in ProjectSettings.get_global_class_list():
		if cls["class"] == ui_name_:
			return load(cls["path"]).new(element_name, element_config)
	push_error("找不到 UI 元素类: ", ui_name_)
	return null


func _get_ui_by_name() -> void:
	ui = create_element(name, ui_name, config)
