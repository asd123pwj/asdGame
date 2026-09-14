class_name Attributes
extends BaseClass
## 属性系统：一个角色的所有属性值 + 作用于它们的 buff（见文件末尾的完整设计说明）。
## 值域分 BASE(基准)/MIN(下限)/MULTIPLIER(随机权重)/CUR(实际比较值)，CUR 由 BASE 经 MULTIPLIER 随机后再叠 CUR 加成得到。
## 被谁用：Character.attrs（角色装配时建）；状态判定、交互结算、指令里的表达式、UI 展示。


## 所属角色。被谁用：各读写（buff 的 per-char 记录、消息广播）。
var me: Character
## Category指的是Buff的所属类别，例如攻击加成A与攻击加成B共同影响攻击值
## {Category: {ValueType: {BuffName: BuffPreset}}}
## 被谁用：add/remove_buff、init_attribute（叠加）、consume_buffs。
var buffs: Dictionary[String, Dictionary] = {}
## {Category: {ValueType: attr_value}}
## 被谁用：get_/_set_（属性的实际存储）。
var attributes: Dictionary[String, Dictionary] = {}
## 和recover()配套，暂时没用
## 被谁用：_set_（记改动前的值）、get_(from_before=true)、_recover。
var attributes_before: Dictionary[String, Dictionary] = {} # 和recover()配套，暂时没用
## 每个属性最近一次"被谁改的"（角色）。被谁用：Interaction_SayChanged 播报、get_changed_by_who。
var attributes_changed_by_who: Dictionary[String, Character] = {}
## 每个属性最近一次"怎么改的"（如 "Init"、交互名）。被谁用：Interaction_SayChanged、get_changed_by_how。
var attributes_changed_by_how: Dictionary[String, String] = {}

## 装配：记下所属角色并装上原型声明的 buff（属性值由 buff 叠加算出，不单独配）。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, attr_type_names: Array[String]) -> void:
    self.me = me
    add_buffs(attr_type_names)



## 批量加 buff。被谁用：_init、运行时批量加。
func add_buffs(buff_names: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for buff_name in buff_names:
        codes.append(add_buff(buff_name))
    return codes

## 加一个 buff：记进 buffs → 重算该属性 → 立刻消耗一次（加 buff 那一下也算使用）→ 广播。
## 被谁用：add_buffs、Interaction_AddBuff、指令。
func add_buff(buff_name: String) -> Enums.Code:
    var buff = BuffPreset.get_(buff_name)
    if Utils.find_dict(buffs, [buff.category, buff.value_type, buff.name], null) != null:
        return Enums.Code.NOT_MODIFIED
    Utils.set_dict(buffs, [buff.category, buff.value_type, buff.name], buff)
    # TODO: 每次添加Buff都会计算，这必然冗余，但不一定浪费性能，先放着
    init_attribute(buff.category, buff.value_type)
    consume_buff(buff) # 添加buff时会使用buff对属性初始化，因此需要consume
    Msg.send_buff_add(me, buff_name)
    return Enums.Code.OK

## 批量移除 buff。被谁用：运行时批量移除。
func remove_buffs(buff_names: Array[String]) -> Array[Enums.Code]:
    var codes = []
    for buff_name in buff_names:
        codes.append(remove_buff(buff_name))
    return codes

## 移除一个 buff：从 buffs 摘掉 → 重算该属性 → 广播。
## 被谁用：remove_buffs、BuffPreset.consume（到次数上限时）、指令。
func remove_buff(buff_name: String) -> Enums.Code:
    var buff = BuffPreset.get_(buff_name)
    var dict:Dictionary = Utils.find_dict(buffs, [buff.category, buff.value_type], {})
    if not dict.erase(buff.name):
        return Enums.Code.NOT_MODIFIED
    # TODO: 每次删除Buff都会计算，这必然冗余，但不一定浪费性能，先放着
    # print(me.name, " remove_buff: ", buff.category, buff.value_type, buff.name)
    init_attribute(buff.category, buff.value_type)
    Msg.send_buff_remove(me, buff.name)
    return Enums.Code.OK

## 有没有这个 buff。被谁用：条件判定/指令。
func check_buff(buff_name: String) -> bool:
    var buff = BuffPreset.get_(buff_name)
    return Utils.find_dict(buffs, [buff.category, buff.value_type, buff.name], null) != null

## 有没有这个属性（某类目的某值域已经算出来了）。被谁用：BuffPreset.apply（字符串取值前判断）。
func check_attribute(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> bool:
    return Utils.find_dict(attributes, [category, impact_type], null) != null

## 重算某属性的某值域并存下：
##   CUR = 用 MULTIPLIER 对 BASE 做随机；其它值域从世界默认值(dao_init_value)起步；
##   然后依次叠上该 (类目, 值域) 的所有 buff。
## 被谁用：add_buff/remove_buff（buff 变化后重算）、get_（首次取值时初始化）、Interaction_Rebirth、指令。
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

## 是否还没跌破下限（只对 CUR 有意义；非 CUR 一律算通过——如金币）。
## 被谁用：set_level_cur（决定本次改动是 OK 还是 FORBIDDEN）。
func check_limitation(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> bool:
    if impact_type != Enums.ValueType.CUR:
        return true
    var value = get_(category, impact_type)
    var value_min = get_(category, Enums.ValueType.MIN)
    return value > value_min

## 消耗单个 buff 的一次使用（内部会到上限就摘掉自己）。
## 被谁用：add_buff（加的时候算一次使用）。
func consume_buff(buff: BuffPreset) -> void:
    buff.consume(me)
## 消耗该 (类目, 值域) 上所有 buff 的一次使用。
## 被谁用：InteractionBase.impact / practice（结算后清次数）、get_(dynamic=true)、Interaction_Rebirth。
func consume_buffs(category: String, impact_type: Enums.ValueType) -> void:
    var dict: Dictionary = Utils.find_dict(buffs, [category, impact_type], {})
    # print("取", me.name, "的", category, "的", Enums.StrValueType[impact_type], "值")
    for buff: BuffPreset in dict.values():
        buff.consume(me)

## 取属性值：from_before 取"改动前"的快照；没算过就先 init_attribute 算出来；
## dynamic 为 true 时再按 MULTIPLIER 随机一次（并消耗 MULTIPLIER 的 buff）。
## 被谁用：几乎所有需要读属性的地方（交互结算、状态判定、指令表达式）。
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
        consume_buffs(category, Enums.ValueType.MULTIPLIER)
    return value

## 取"最近一次改动原因"（没人改过就是空串）。
## 被谁用：Interaction_SayChanged 播报。
func get_changed_by_how(category: String) -> String:
    return Utils.find_dict(attributes_changed_by_how, [category], "")
## 取"最近一次改动者"（没人改过就是 null）。
## 被谁用：Interaction_SayChanged 播报。
func get_changed_by_who(category: String) -> Character:
    return Utils.find_dict(attributes_changed_by_who, [category], null)


# func get_dynamic_value(value: int, multiplier: int) -> int:
#     """ 无限范围的近似等比随机 """
#     var v: int = RandSys.rand.randi_range(0, multiplier)
#     if v != 0: # 抽到当前level
#         return value
#     v = RandSys.rand.randi_range(0, 1)  # 抽方向
#     var dir: int = 0
#     if v == 0:                       # 抽到减少
#         dir = -1
#     elif v == 1:        # 抽到增加
#         dir = 1
#     var value_changed: int = 0
#     while true:
#         value_changed += dir         # 记录变化量
#         v = RandSys.rand.randi_range(0, multiplier)  # 重新抽，但只往1个方向抽
#         if v > 0:                    # 抽到偏移后的当前值
#             break
#     return value + value_changed
## 简单放大系数（当前就是 ×2）。
## 被谁用：get_dynamic_value 内部。
func scale_value(n: int) -> int:
    return n * 2
## 按 MULTIPLIER 做"无限范围的近似等比随机"：离中心越远，抽到当前值概率越小。
## center_distance 是"当前值到基准值的距离"；allow_add/subtract 控制只许涨/只许跌。
## 被谁用：init_attribute（CUR 初始化）、get_(dynamic=true)、InteractionBase.practice。
func get_dynamic_value(value: int, multiplier: int, center_distance: int = 0, allow_add: bool = true, allow_subtract: bool = true) -> int:
    """ 无限范围的近似等比随机 """
    # 距离中心越远，抽到当前值概率越小
    multiplier = scale_value(multiplier)
    var dir: int
    if center_distance > 0:
        dir = -1 if RandSys.rand.randi_range(0, center_distance + 1) <= 0 else 1
    else:
        dir = -1 if RandSys.rand.randi_range(0 + center_distance, 1) <= 0 else 1

    if dir == 1 and not allow_add:
        return value
    elif dir == -1 and not allow_subtract:
        return value

    var value_changed: int = 0
    var from
    var to
    var offset
    while true:
        offset = scale_value(value_changed)
        from = min(0, -center_distance * dir + offset)
        to = max(multiplier, multiplier - center_distance * dir + offset)
        if RandSys.rand.randi_range(from, to) > 0:
            break
        value_changed += dir         # 记录变化量

    return value + value_changed

## 写属性值：记 before 快照 → 写 attributes → 值真的变了且是 CUR 就记"谁/怎么改的"并广播；
## 返回实际偏移。
## 被谁用：init_attribute、set_level_cur、_recover。
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
        Msg.send_attr_changed(me, category)

    return value_new - value_before

## 把属性回滚到 before 快照，返回偏移。
## 被谁用：set_level_cur 里那行被注释的"超出限制就回滚"（暂未启用）。
func _recover(category: String, impact_type: Enums.ValueType = Enums.ValueType.CUR) -> int:
    var value_ori = Utils.find_dict(attributes_before, [category, impact_type])
    var value_offset = _set_(category, value_ori, impact_type)
    return value_offset

## 设定 CUR 的入口（写值 + 判下限 + 打包 ChangeResult）。
## 被谁用：InteractionBase.impact（交互结算是唯一入口）、practice。
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
