class_name UIPreset
extends PresetRegister
## UI 预设（设计见 Script/UI/UI.md）。
## 一条 UI 配置 = name(唯一名) + ui_name(实现类名) + config(显示/交互配置)。
## 按 ui_name 实例化对应 UIBase 并注册进 static _we；开启由 UIInteract_OpenClose.open 统一负责。

## 预设名（独立 UI 的登记名就是它）。
## 被谁用：UIInteract_OpenClose.open（按名查）、UIPreset.get_。
var name: String
## 实现类名（UIBase 子类名，如 "UI_Panel"）。
## 被谁用：create_element（靠 ProjectSettings 的全局类表按类名找脚本）。
var ui_name: String
## 该 UI 的配置（见 Config/UI/）。
## 被谁用：_get_ui_by_name（造模板）、UIInteract_OpenClose._build_open（独立 UI 用它、寄主型深拷贝它）。
var config: Dictionary
## 本预设的模板实例（一份，代表"这个预设"）。
## 被谁用：UIInteract_OpenClose._build_open（**只有独立 UI** 直接 build 它）。
## 注意它是共享实例：寄主型（菜单等）走 create_element 造新实例 + 深拷贝配置，别往它上面存实例态。
var ui: UIBase

## 全部预设。
## 被谁用：UIPreset.get_（UIInteract_OpenClose.open 按名查）。
static var _we: Dictionary[String, UIPreset] = {}


## 注册一条预设，并立刻造出模板实例（配置类实例化时就被调用）。
## 被谁用：PresetRegister 的注册流程。
func _init(name_: String, ui_name_: String, config_: Dictionary = {}) -> void:
	_we[name_] = self
	name = name_
	ui_name = ui_name_
	config = config_
	_get_ui_by_name()


## 按名取预设（没有返回 null）。
## 被谁用：UIInteract_OpenClose.open。
static func get_(name_: String) -> UIPreset:
	return _we.get(name_)


## 按类名实例化一个 UI 元素（根 UI 与子元素共用的工厂）。
## 被谁用：_get_ui_by_name、UIBase._build_children / add_child_element。
static func create_element(element_name: String, ui_name_: String, element_config: Dictionary = {}) -> UIBase:
	for cls in ProjectSettings.get_global_class_list():
		if cls["class"] == ui_name_:
			@warning_ignore("unsafe_method_access")
			return load(cls["path"]).new(element_name, element_config)
	push_error("找不到 UI 元素类: ", ui_name_)
	return null


## 造本预设的模板实例。
## 被谁用：_init。
func _get_ui_by_name() -> void:
	ui = create_element(name, ui_name, config)
