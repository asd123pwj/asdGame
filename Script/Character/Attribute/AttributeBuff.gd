class_name AttributeBuff
extends PresetRegister


""" ----- individual ----- """
var name: String
var attr_type_name: String
var buff_value: int
## 可选：Enums.ValueType.{CUR/BASE/FINAL}，MIN不生效（因为状态判断里和定值对比，加MIN后就变成变值了
var impact_type: Enums.ValueType

""" ----- Global ----- """
static var _we: Dictionary[String, AttributeBuff] = {}
# static var new_: Callable

func _init(name: String, type_name: String, buff_value: int, impact_type: Enums.ValueType) -> void:
    _we[name] = self
    self.name = name
    self.attr_type_name = type_name
    self.buff_value = buff_value
    self.impact_type = impact_type
    # _presets[name] = self

static func get_(name: String) -> AttributeBuff:
    return _we[name]
# static func add(name: String, args: Array) -> void:
#     _presets[name] = args



func impact(value: int) -> ChangeResult:
    # if impact_type != impact_type:
    #     return ChangeResult.new(Enums.Code.NOT_FOUND, value, value, 0)
    return ChangeResult.new(Enums.Code.OK, value, buff_value+value, buff_value)
    