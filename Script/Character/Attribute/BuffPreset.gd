class_name BuffPreset
extends PresetRegister
## 增益/减益预设：对某个属性的"一层修正"（加/减/乘/除/设为某值），可限次数。
## 角色的属性值 = 基础值依次叠过所有 buff（见 Attributes.init_attribute / apply）。
## 被谁用：Attributes.add_buff/remove_buff/consume_buffs、Archetype 的 buffs 字段。

""" ---------- individual ---------- """
""" ----- Config ----- """
## 预设名（唯一）。被谁用：Attributes 的 buffs 字典键、指令。
var name: String
## 作用在哪个属性类目上（如 "Health"）。被谁用：Attributes 叠加时定位。
var category: String
## 作用在哪个值域（BASE/CUR/MIN/FINAL…）。被谁用：同上。
var value_type: Enums.ValueType
## 修正量：整数直接用；字符串则视为"另一个属性名"，取其当前值当修正量。
var value #: int | String
## 修正方式（加/减/乘/除/设为）。被谁用：apply。
var method: Enums.ModificationMethod
## 最多生效次数（<=0 表示不限）。被谁用：consume。
var max_uses: int
## 每个角色已消耗的次数（因角色而异，所以按角色记）。被谁用：consume。
var uses : Dictionary[Character, int] = {}

""" ----- Global ----- """
## 全部预设：名 -> 实例。被谁用：BuffPreset.get_。
static var _we: Dictionary[String, BuffPreset] = {}


""" ---------- Init ---------- """
## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
## 注册一条 buff 预设。被谁用：PresetRegister 的注册流程（配置里按位置传参）。
func _init(
        name: String,
        category: String,
        value_type: Enums.ValueType,
        value,#: int | String
        method: Enums.ModificationMethod = Enums.ModificationMethod.ADD,
        max_uses: int = -1
        ) -> void:
    _we[name] = self
    self.name = name
    self.category = category
    self.value_type = value_type
    self.value = value
    self.method = method
    self.max_uses = max_uses

## 按名取预设。被谁用：Attributes.add_buff/remove_buff/consume_buffs/check_buff。
static func get_(name: String) -> BuffPreset:
    return _we[name]

## 消耗一次：到次数上限就把自己从角色身上摘掉；每次都广播"消耗"消息（注意消息在计算前发）。
## 被谁用：Attributes.consume_buffs。
func consume(char_: Character) -> void:
    if max_uses > 0:
        if not char_ in uses:
            uses[char_] = 0
        if uses[char_] >= max_uses:
            char_.attrs.remove_buff(name)
        uses[char_] += 1
        Msg.send_buff_consume(char_, name) # 注意消息发送在计算前

## 把本 buff 作用到 value 上并返回新值：value 为字符串时取其当前属性值当修正量。
## 被谁用：Attributes.init_attribute（叠加所有 buff）。
func apply(value: int, char_: Character) -> int:
    var value_offset: int
    match typeof(self.value):
        TYPE_INT:
            value_offset = self.value
        TYPE_STRING:
            if char_.attrs == null or (not char_.attrs.check_attribute(self.value)):
                value_offset = 0
            else:
                value_offset = char_.attrs.get_(self.value)
    if method == Enums.ModificationMethod.ADD:
        return value + value_offset
    elif method == Enums.ModificationMethod.SUBTRACT:
        return value - value_offset
    elif method == Enums.ModificationMethod.MULTIPLY:
        return value * value_offset
    elif method == Enums.ModificationMethod.DIVIDE:
        @warning_ignore("integer_division")
        return value / value_offset
    elif method == Enums.ModificationMethod.SET:
        return value_offset
    else:
        return value_offset
