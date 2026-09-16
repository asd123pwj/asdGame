class_name UIInteract_SwapConfig
extends UIInteractBase
## UI 交互：**对调配置两项**（`UIInteract.swap_config`）——开关式按钮的底座。
## 组内共用与指令前缀见基类 Script/UI/Interact/UIInteractBase.gd（`_as_ui` 由基类提供）。


## 对调目标 UI 的 config 里两项（A ↔ B），实现"点一下换一套配置"的开关式按钮。
## 典型用法是把两套 `events` / `content` 都写在元素上，点击时"做事 + 换一套"——
## 一条事件串可以写多条命令（用 `\v` 分隔，见 CmdSys.execute），所以：
##   "Mouse Left" → UIInteract.open <宿主> CloseButton <宿主> \v swap_config $self events events_2
##                  \v swap_config $self content content_2
## 换完 `config["events"]` 就是另一套（下一次点击自然走那套），`content` 与显示同步刷新。
## 于是普通 UI_Label / UI_Image 就能当开关用，不需要专门的开关元素。
## 被谁用：预设里配 `"Mouse Left"` 的项（Config/UI/UIPreset_Menu.gd 的 MenuEdit/CloseToggle、EnableDrag）。
static func swap_config(target: UIBase, key_a: String, key_b: String) -> void:
	var ui := _as_ui(target, "swap_config")
	if ui == null:
		return
	ui.swap_config(key_a, key_b)
