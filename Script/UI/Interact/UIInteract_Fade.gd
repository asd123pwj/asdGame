class_name UIInteract_Fade
extends UIInteractBase
## UI 交互：**渐隐 / 渐显**（`UIInteract.fade_to`）。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## 透明度渐隐/渐显：alpha 为目标透明度(0~1)，duration 为补间秒数。
## 指令里可以只写到 alpha（不写就用签名里的默认值——CmdSys._build_args 会填默认值），
## 但建议写全，一眼看得出时长。
## 被谁用：预设里 "UIInteract.fade_to @self.parent 0.0 0.5" 这类配置。
static func fade_to(target: UIBase, alpha: float, duration: float = 0.25) -> void:
	var ui := _as_ui(target, "fade_to")
	if (ui == null) or (ui.control == null):
		return
	var tween: Tween = ui.control.create_tween()
	tween.tween_property(ui.control, "modulate:a", clampf(alpha, 0.0, 1.0), duration)
	Msg.send_ui_fade(ui, alpha)
