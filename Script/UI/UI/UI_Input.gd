class_name UI_Input
extends UIBase
## 输入框元素（基于 LineEdit）：content 是**配置里写的初值**（refresh 时写进框里，正在编辑时不回写），
## 回车提交 → 派发事件 QName.input_submit。
##
## **元素自己没有任何特判**：不连引擎信号，也不写死"点我进编辑"——那只是一条普通事件配置，
## 用什么事件触发由写配置的人决定：
##   ["Name", "UI_Input", {
##       "size": [240, 0],
##       "events": [
##           [QName.mouseLeft, 'UIInteract.begin_edit(self)'],        # 点它进编辑（换事件就改这一条）
##           [QName.input_submit,
##               # 送到绑定名指的那个 UI：绑定名记在**窗口**的 config 上，用 host 取（不必数级数）；
##               # 路径写成**带引号的字符串**（不然里面的 @ID.config 会被当取值式解析）
##               'Utils.write("UiSys.get_ui(host.config.bind).config.content", self.control.text)'
##               + '\vUtils.write("self.config.content")'              # 不写值 = 清空框（content 置 null）
##               + '\vUIInteract.end_edit(self)'                       # 先退出编辑（想"提交完继续打字"就不写这条）
##               + '\vUiSys.get_ui(host.config.bind).refresh("content")'   # 只刷改过的那一项
##               + '\vself.refresh("content")']],                          # 自己也是只改了 content
##           # **改了什么就刷什么**；顺序别反——编辑中的输入框会跳过刷新，先刷就把"清空"漏掉了
##       ],
##   }]
## 框里正在打的字**不往 content 同步**：要用就用取值链直接读 `self.control.text`（见 UI.md）。
## "送到哪"由绑定名给出：`host.config.bind` 是**窗口**上记的那个名字（host = 沿 parent 爬到顶那个 UI）；
## 名字没设 / 对应 UI 不在登记表里时，整条路径写不进去，Utils.write 会警告一声（不静默）。
##
## 编辑状态记在 InputSys（`edit_ui`）：`UIInteract_Edit.begin_edit` 抢焦点并置上它；
## 结束走 `UIInteract.end_edit` 命令，或者"点别处"（PointerDetect.key 开头先把编辑收掉）。
## 事件本身走的还是项目自己的链（配置里的 mouseLeft + 需要时冒泡给父级）。


func _create_control() -> Control:
	return LineEdit.new()


## config["content"] → 框里的文字（配置初值、或被写过的 content）。
## **正在编辑时不动**：框里的字还没进 content（不同步），这时候回写等于把人打的字冲掉。
## 框里**正在打的字不回写 content**：要用就用取值链直接读 `self.control.text`（见文件头）。
## 被谁用：build() 末尾、配置里改完 content 紧跟的 `self.refresh("content")`。
func refresh(key: String = "") -> void:
	super.refresh(key)
	if key != "" and key != "content":
		return                      # 只认自己这一项，别的键交给 super / 别的子类
	if not (control is LineEdit):
		return
	var line: LineEdit = control
	if line.has_focus():
		return                      # 正在编辑：别把人家打的字冲掉
	var v: Variant = config.get("content")
	line.text = "" if v == null else str(v)
