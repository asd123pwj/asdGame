class_name Attributes
extends RefCounted

var me: Character
## Category指的是Buff的所属类别，例如攻击加成A与攻击加成B共同影响攻击值
## {Category: {ValueType: {BuffName: BuffPreset}}}
var buffs: Dictionary[String, Dictionary] = {}
## {Category: {ValueType: attr_value}}
var attributes: Dictionary[String, Dictionary] = {}
var attributes_before: Dictionary[String, Dictionary] = {} # 和recover()配套，暂时没用
var attributes_changed_by_who: Dictionary[String, Character] = {}
var attributes_changed_by_how: Dictionary[String, String] = {}

func _init(me: Character, attr_type_names: Array[String]) -> void:
    self.me = me
    add_buffs(attr_type_names)



func add_buffs(buff_names: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for buff_name in buff_names:
        codes.append(add_buff(buff_name))
    return codes

func add_buff(buff_name: String) -> Enums.Code:
    var buff = BuffPreset.get_(buff_name)
    if Utils.find_dict(buffs, [buff.category, buff.value_type, buff.name], null) != null:
        return Enums.Code.NOT_MODIFIED
    Utils.set_dict(buffs, [buff.category, buff.value_type, buff.name], buff)
    # TODO: 每次添加Buff都会计算，这必然冗余，但不一定浪费性能，先放着
    init_attribute(buff.category, buff.value_type)
    MsgHubChar.send_buff_add(me, buff_name)
    return Enums.Code.OK

func remove_buffs(buff_names: Array[String]) -> Array[Enums.Code]:
    var codes = []
    for buff_name in buff_names:
        codes.append(remove_buff(buff_name))
    return codes

func remove_buff(buff_name: String) -> Enums.Code:
    var buff = BuffPreset.get_(buff_name)
    var dict:Dictionary = Utils.find_dict(buffs, [buff.category, buff.value_type], {})
    if not dict.erase(buff.name):
        return Enums.Code.NOT_MODIFIED
    # TODO: 每次删除Buff都会计算，这必然冗余，但不一定浪费性能，先放着
    init_attribute(buff.category, buff.value_type)
    MsgHubChar.send_buff_remove(me, buff.name)
    return Enums.Code.OK

func check_buff(buff_name: String) -> bool:
    var buff = BuffPreset.get_(buff_name)
    return Utils.find_dict(buffs, [buff.category, buff.value_type, buff.name], null) != null

func check_attribute(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> bool:
    return Utils.find_dict(attributes, [category, impact_type], null) != null

func init_attribute(
        category: String, 
        impact_type: Enums.ValueType = Enums.ValueType.CUR,
        changed_by_how: String = "Init", 
        changed_by_who: Character = me
        ) -> int:
    var value: int
    if impact_type == Enums.ValueType.CUR:
        # CUR的值取决于BASE和MULTIPLIER
        var value_base = init_attribute(category, Enums.ValueType.BASE)
        var multiplier = init_attribute(category, Enums.ValueType.MULTIPLIER)
        value = get_dynamic_value(value_base, multiplier)
    else:
        # 其它值的基准值从世界默认值开始叠加
        value = Sys.sysCfg.dao_init_value[impact_type]
    var dict: Dictionary = Utils.find_dict(buffs, [category, impact_type], {})
    for buff: BuffPreset in dict.values():
        value = buff.apply(value, me)
    _set_(category, value, impact_type, changed_by_how, changed_by_who)
    return value

func check_limitation(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> bool:
    if impact_type != Enums.ValueType.CUR:
        return true
    var value = get_(category, impact_type)
    var value_min = get_(category, Enums.ValueType.MIN)
    return value > value_min

func get_(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR, from_before: bool = false, dynamic: bool = false) -> int:
    var value
    if from_before:
        value = Utils.find_dict(attributes_before, [category, impact_type], null)
    if value == null:
        value = Utils.find_dict(attributes, [category, impact_type], null)
    if value == null:
        value = init_attribute(category, impact_type)
    if dynamic:
        value = get_dynamic_value(value, get_(category, Enums.ValueType.MULTIPLIER))
    return value

func get_changed_by_how(category: String) -> String:
    return Utils.find_dict(attributes_changed_by_how, [category], "")
func get_changed_by_who(category: String) -> Character:
    return Utils.find_dict(attributes_changed_by_who, [category], null)

func get_dynamic_value(value: int, multiplier: int) -> int:
    """ 无限范围的近似等比随机 """
    var v: int = RandSys.rand.randi_range(0, multiplier)
    if v != 0: # 抽到当前level
        return value
    v = RandSys.rand.randi_range(0, 1)  # 抽方向
    var dir: int = 0
    if v == 0:                       # 抽到减少
        dir = -1
    elif v == 1:        # 抽到增加
        dir = 1
    var value_changed: int = 0
    while true:
        value_changed += dir         # 记录变化量
        v = RandSys.rand.randi_range(0, multiplier)  # 重新抽，但只往1个方向抽
        if v > 0:                    # 抽到偏移后的当前值
            break
    return value + value_changed

func _set_(
        category: String, 
        value_new: int, 
        impact_type: Enums.ValueType = Enums.ValueType.CUR, 
        changed_by_how: String = "", 
        changed_by_who: Character = me) -> int:
    var value_before = Utils.find_dict(attributes, [category, impact_type], value_new)
    Utils.set_dict(attributes_before, [category, impact_type], value_before)
    Utils.set_dict(attributes, [category, impact_type], value_new)
    # 暂时只关注CUR
    if value_new != value_before and impact_type == Enums.ValueType.CUR:
        Utils.set_dict(attributes_changed_by_how, [category], changed_by_how)
        Utils.set_dict(attributes_changed_by_who, [category], changed_by_who)
        MsgHubChar.send_attr_changed(me, category)

    return value_new - value_before

func _recover(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> int:
    var value_ori = Utils.find_dict(attributes_before, [category, impact_type])
    var value_offset = _set_(category, value_ori, impact_type)
    return value_offset

func set_level_cur(
        category: String, 
        value_new: int, 
        changed_by_how: String, 
        changed_by_who: Character) -> ChangeResult:
    var value_ori = get_(category)
    var value_offset = _set_(category, value_new, Enums.ValueType.CUR, changed_by_how, changed_by_who)
    var code: Enums.Code
    if check_limitation(category):
        if value_offset != 0:
            code = Enums.Code.OK
        else:
            code = Enums.Code.NOT_MODIFIED
    else:
        # _recover(category) # TODO: 先放着看后面怎么触发超出限制
        code = Enums.Code.FORBIDDEN

    return ChangeResult.new(
        code, value_ori, value_new, value_offset
    )



## 现在的逻辑是，将所有属性看作加成，
## 以Health这个category为例，它有BASE、CUR、MIN、MULTIPLIER四个值
## BASE是种族基准值，MIN是最低值，MULTIPLIER是随机权重（越大越稳定）
## CUR是实际比较值，为了取CUR，需要先取BASE，在用MULTIPLIER随机，再取CUR加成
## BASE是基准值，重置时恢复为基准值，随机时以BASE为中心随机
## 首先遍历BASE，设世界初始值为0，种族有生命+1，生命*2两个属性，则取(0+1)*2=2
## MULTIPLIER是随机权重，每次随机有MULTIPLIER/(MULTIPLIER+1)的概率取到自身
## 随后应用MULTIPLIER随机，MULTIPLIER越大，取到2的概率越大，见get_dynamic_value()
## 设经过MULTIPLIER后，值不变，为2
## CUR为最终值，用于各类比较与判断
## 再应用CUR加成，设有加成**生命-3**，则取2-3=-1
## MIN为极限值，低于MIN则失败
## 最后判断MIN，设MIN的世界初始值为0，无加成，则MIN取0
## CUR小于MIN，则此次取CUR失败，对于生命来说，失败则死亡，对于金币来说，失败则取消交易
## 
## 现在来看CUR的加成**生命-3**，它是战斗引发的加成
## 有战斗，攻击者的CUR比防御者CUR高3，这令防御者获得加成**生命-3**，
## 但添加**生命-3**不会立即死亡，而是要等待下次取CUR时，才会判断MIN
## 因此，战斗失败不会立即死亡，可以选择脱离战斗回血
## 那这样，战斗不应该是即时战斗？
## 
## 又改了下，现在是即时判断死亡，造成伤害不是添加加成，而是直接修改attributes
