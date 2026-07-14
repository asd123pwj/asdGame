class_name Attribute
extends RefCounted

var me: Character
var attr_types: Dictionary[String, AttributeType] = {}
## {attr_type_name: {impact_type: {attr_buff_name: AttributeBuff}}}
var attr_buffs: Dictionary[String, Dictionary] = {}
## 先天基准值，基于种族标准值随机获得，后天成长值会靠近先天基准值
## 先天基准值无法成长，只能通过Buff或等效重生改变
var _level_bases: Dictionary[String, int] = {}
## 后天成长值，基于个人天赋值随机获得，实际表现值会靠近后天成长值
## 后天成长值可成长，离先天基准值越远，成长越困难
var _level_curs: Dictionary[String, int] = {}
## 最低阈值，后天成长值不能低于阈值
## 如生命需大于0，金币需大于-1
var _level_mins: Dictionary[String, int] = {}

func _init(me: Character, attr_type_names: Array[String], attr_buff_names: Array[String]) -> void:
    self.me = me
    add_attr_types(attr_type_names)
    add_attr_buffs(attr_buff_names)
    _init_all_attr()

""" ---------- Attr Type ---------- """
func add_attr_types(attr_types: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for attr_type_name in attr_types:
        codes.append(add_attr_type(attr_type_name))
    return codes

func add_attr_type(attr_type_name: String) -> Enums.Code:
    if attr_types.has(attr_type_name):
        return Enums.Code.NOT_MODIFIED
    attr_types[attr_type_name] = AttributeType.new_.call([attr_type_name])
    MsgHubChar.send_type_add(me, attr_type_name)
    return Enums.Code.OK

func remove_attr_types(attr_types: Array[String]) -> Array[Enums.Code]:
    var codes = []
    for attr_type_name in attr_types:
        codes.append(remove_attr_type(attr_type_name))
    return codes

func remove_attr_type(attr_type_name: String) -> Enums.Code:
    if not attr_types.erase(attr_type_name):
        return Enums.Code.NOT_MODIFIED
    MsgHubChar.send_type_remove(me, attr_type_name)
    return Enums.Code.OK

func get_attr_type(attr_type_name: String) -> AttributeType:
    if attr_types.has(attr_type_name):
        return attr_types[attr_type_name]
    else:
        return null


""" ---------- Attr Buff ---------- """
func add_attr_buffs(attr_buff_names: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for attr_buff_name in attr_buff_names:
        codes.append(add_attr_buff(attr_buff_name))
    return codes

func add_attr_buff(attr_buff_name: String) -> Enums.Code:
    var attr_buff = AttributeBuff.new_.call([attr_buff_name])
    var impact_dict = Utils.get_dict(attr_buffs, attr_buff.attr_type_name, attr_buff.impact_type)
    if impact_dict.has(attr_buff_name):
        return Enums.Code.NOT_MODIFIED
    impact_dict[attr_buff_name] = attr_buff
    MsgHubChar.send_buff_add(me, attr_buff_name)
    return Enums.Code.OK

func remove_attr_buffs(attr_buff_names: Array[String]) -> Array[Enums.Code]:
    var codes = []
    for attr_buff_name in attr_buff_names:
        codes.append(remove_attr_buff(attr_buff_name))
    return codes

# func remove_attr_buff(attr_buff_name: String) -> Enums.Code:
#     var attr_buff = AttributeBuff.new_.call([attr_buff_name])
#     if attr_buffs.has(attr_buff.attr_type_name):
#         if attr_buffs[attr_buff.attr_type_name].has(attr_buff.impact_type):
#             @warning_ignore("unsafe_method_access")
#             if attr_buffs[attr_buff.attr_type_name][attr_buff.impact_type].has(attr_buff_name):
#                 @warning_ignore("unsafe_method_access")
#                 attr_buffs[attr_buff.attr_type_name][attr_buff.impact_type].erase(attr_buff_name)
#                 return Enums.Code.OK
#     return Enums.Code.NOT_MODIFIED
func remove_attr_buff(attr_buff_name: String) -> Enums.Code:
    var attr_buff = AttributeBuff.new_.call([attr_buff_name])
    var impact_dict = Utils.find_dict(attr_buffs, attr_buff.attr_type_name, attr_buff.impact_type)
    if impact_dict.is_empty():
        return Enums.Code.NOT_MODIFIED
    if not impact_dict.erase(attr_buff_name):
        return Enums.Code.NOT_MODIFIED
    MsgHubChar.send_buff_remove(me, attr_buff_name)
    return Enums.Code.OK


func get_attr_buffs(attr_type_name: String, impact_type: Enums.ValueType) -> Dictionary:
    return Utils.find_dict(attr_buffs, attr_type_name, impact_type)

    # if attr_buffs.has(attr_type_name):
    #     if attr_buffs[attr_type_name].has(impact_type):
    #         return attr_buffs[attr_type_name][impact_type]
    # return {}




""" ---------- Level ---------- """
""" ----- Init ----- """
func _init_all_attr() -> void:
    for attr_type_name in attr_types.keys():
        init_level_min(attr_type_name)
        init_level_base(attr_type_name)
        init_level_cur(attr_type_name)


""" ----- Basic ----- """
func _init_level(attr_type_name: String, impact_type: Enums.ValueType) -> int:
    var _attr_type = get_attr_type(attr_type_name)
    var level: int
    # 取基值
    if impact_type == Enums.ValueType.BASE:
        level = _attr_type.level_base
    elif impact_type == Enums.ValueType.CUR:
        level = get_level_base(attr_type_name)
    elif impact_type == Enums.ValueType.FINAL:
        level = get_level_cur(attr_type_name)
    elif impact_type == Enums.ValueType.MIN:
        level = _attr_type.level_min
    else:
        pass ## 报错
    # 加Buff
    level = _apply_buffs(attr_type_name, impact_type, level)
    # 取动态属性（极限值为定值，例如生命极限为0）
    if impact_type != Enums.ValueType.MIN:
        level = _attr_type.get_dynamic_level(level)
    return level

func _apply_buffs(attr_type_name: String, impact_type: Enums.ValueType, level: int) -> int:
    var _attr_buffs := get_attr_buffs(attr_type_name, impact_type)
    for attr_buff_name in _attr_buffs.keys():
        var attr_buff : AttributeBuff = _attr_buffs[attr_buff_name]
        level = attr_buff.impact(level).new
    return level


""" ----- Level Cur 后天成长值 ----- """
func get_level_cur(attr_type_name: String) -> int:
    return _level_curs[attr_type_name] if _level_curs.has(attr_type_name) else init_level_cur(attr_type_name)

func init_level_cur(attr_type_name: String) -> int:
    _level_curs[attr_type_name] = _init_level(attr_type_name, Enums.ValueType.CUR)
    return _level_curs[attr_type_name]


""" ----- Level Base 先天基准值 ----- """
func get_level_base(attr_type_name: String) -> int:
    return _level_bases[attr_type_name] if _level_bases.has(attr_type_name) else init_level_base(attr_type_name)

func init_level_base(attr_type_name: String) -> int:
    _level_bases[attr_type_name] = _init_level(attr_type_name, Enums.ValueType.BASE)
    return _level_bases[attr_type_name]


""" ----- Level Min 最低阈值 ----- """
func get_level_min(attr_type_name: String) -> int:
    return _level_mins[attr_type_name] if _level_mins.has(attr_type_name) else init_level_min(attr_type_name)

func init_level_min(attr_type_name: String) -> int:
    _level_mins[attr_type_name] = _init_level(attr_type_name, Enums.ValueType.MIN)
    return _level_mins[attr_type_name]


""" ----- Level Final 实际表现值 ----- """
func get_level_final(attr_type_name: String) -> int:
    return _init_level(attr_type_name, Enums.ValueType.FINAL)



