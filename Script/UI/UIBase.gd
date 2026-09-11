class_name UIBase
extends BaseClass
## UI 元素基类（设计见 Script/UI/UI.md）。
## extends BaseClass，内部持 control: Control（不直接继承 Control）。
## 显示内容挂到 control 下；交互统一走 Msg（不用自定义 signal）；
## 指针输入由 PointDetect 用 InputSys 检测命中后回调本对象（不用引擎 gui_input）。

var name: String = ""
var config: Dictionary = {}
var control: Control

## 交互开关（可由 config 覆盖）
var draggable: bool = false
var closeable: bool = false
var scalable: bool = false
var submittable: bool = false
var track_id: int = -1

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

const MIN_SIZE: Vector2 = Vector2(60, 40)


func _init(name_: String = "", config_: Dictionary = {}) -> void:
	name = name_
	config = config_


## 生成控件树，返回 control（供 UiSystem 挂载）。指针交互由 PointDetect 驱动。
func build() -> Control:
	control = _create_control()
	_apply_config()
	return control


## 虚接口：子类生成自身外观控件。
func _create_control() -> Control:
	return Control.new()


func _apply_config() -> void:
	if config.has("position") and config["position"] is Array:
		var p: Array = config["position"]
		if p.size() >= 2:
			control.position = Vector2(float(p[0]), float(p[1]))
	if config.has("size") and config["size"] is Array:
		var s: Array = config["size"]
		if s.size() >= 2:
			control.custom_minimum_size = Vector2(float(s[0]), float(s[1]))
			control.size = control.custom_minimum_size
	if config.has("draggable"):
		draggable = bool(config["draggable"])
	if config.has("closeable"):
		closeable = bool(config["closeable"])
	if config.has("scalable"):
		scalable = bool(config["scalable"])
	if config.has("submittable"):
		submittable = bool(config["submittable"])
	if config.has("track_id"):
		track_id = int(config["track_id"])


## 指针按下（PointDetect 派发）：开始拖动并记录偏移，发 press。
func on_pointer_down() -> void:
	if draggable:
		_dragging = true
		_drag_offset = InputSys.mouse_position - control.global_position
	Msg.send_ui_interact(self, "press")


## 指针按住移动（PointDetect 每帧派发）：拖动跟随指针，发 drag。
func on_pointer_move() -> void:
	if not _dragging:
		return
	control.global_position = InputSys.mouse_position - _drag_offset
	Msg.send_ui_interact(self, "drag")


## 指针抬起（PointDetect 派发）：结束拖动，发 release。
func on_pointer_up() -> void:
	if not _dragging:
		return
	_dragging = false
	Msg.send_ui_interact(self, "release")


## 提交键（PointDetect 派发）：发 submit。
func on_submit() -> void:
	if submittable:
		Msg.send_ui_interact(self, "submit")


## 关闭：发交互消息并隐藏。
func close() -> void:
	Msg.send_ui_interact(self, "close")
	if control != null:
		control.hide()


## 透明度渐隐/渐显：发交互消息并补间。
func fade_to(target: float, duration: float = 0.25) -> void:
	Msg.send_ui_interact(self, "fade", target)
	if control == null:
		return
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate:a", clampf(target, 0.0, 1.0), duration)
