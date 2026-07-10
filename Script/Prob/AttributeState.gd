class_name AttributeState
extends RefCounted

var _type_name: String
var _level_cur: int
var _attr_type: AttributeType
# var me: Character
# var attrs: Dictionary = {}

func _init(type_name: String) -> void:
    self._type_name = type_name
    _init_type()
    _init_level()

func _init_type() -> void:
    _attr_type = AttributeType.get_(self._type_name)

func _init_level() -> void:
    var level_base = get_level_base()
    var level_cur = _attr_type.get_random_level(level_base)
    set_level_cur(level_cur)



func get_level_cur() -> int:
    # 暂时是用固定level，后续会加buff，可以调整自身的当前等级
    return _level_cur

func get_random_level_cur() -> int:
    return _attr_type.get_random_level(get_level_cur())

func get_level_base() -> int:
    # 暂时是用固定level，后续会加buff，可以调整自身的基准等级
    return _attr_type.level_base

func get_random_level_base() -> int:
    return _attr_type.get_random_level(get_level_base())

func get_attr_type() -> AttributeType:
    return _attr_type

func get_level_min() -> int:
    # 暂时是用固定level，后续会加buff，可以调整自身的最小等级
    return _attr_type.level_min






## 设置当前等级
## @param level_new: 新等级
func set_level_cur(level_new: int) -> AttributeSetResult:
    var level_ori = _level_cur
    var level_offset = level_new - level_ori
    var code: Enums.Code
    if level_new > get_level_min():
        _level_cur = level_new
        if level_ori != level_new:
            code = Enums.Code.OK
        else:
            code = Enums.Code.NOT_MODIFIED
    else:
        if get_attr_type().allow_negative:
            _level_cur = level_new
        code = Enums.Code.FORBIDDEN

    return AttributeSetResult.new(
        code, level_ori, level_new, level_offset
    )
