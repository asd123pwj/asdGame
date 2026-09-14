class_name ChangeResult
extends BaseClass
## 属性变更结果：把一次改动"成没成 / 原值 / 目标值 / 实际偏移"一起返回，
## 调用方不用自己去比较改动前后（见 Script/Character/Attribute/Attributes.md）。
## 被谁用：Attributes.change 系列（如 add/consume/_change_cur 的返回值）、
##           Interaction 基类攻击/治疗/消耗/练习等方法把它们组合起来做结算。

## 结果码（OK / FORBIDDEN 等，见 Enums.Code）。被谁用：调用方判成败。
var code: Enums.Code
## 改动前的值。
var ori: int
## 请求改成的新值（未截断）。
var new: int
## 实际生效的偏移（被上下限截断后的差值）。
var offset: int

## 打包一次变更结果。
## 被谁用：Attributes 里 ChangeResult.new(...)。
func _init(code: Enums.Code, ori: int, new: int, offset: int) -> void:
	self.code = code
	self.ori = ori
	self.new = new
	self.offset = offset
