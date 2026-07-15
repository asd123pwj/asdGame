class_name AttributeType
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var level_base: int
var level_min: bool 
var multiplier: int
## 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
var allow_negative: bool

# """ ----- State ----- """
# var _level_cur: int
# var _buffs: Dictionary[Enums.ValueType, AttributeType] = {}

""" ----- Global ----- """
static var _we: Dictionary[String, AttributeType] = {}
# static var new_: Callable
# static var _presets: Dictionary[String, Array] = {}


""" ---------- Init ---------- """
## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
func _init(
        name: String,
        level_base: int, 
        multiplier: int,
        level_min: int = INT64_MIN,
        allow_negative: bool = true 
        ) -> void:
    _we[name] = self
    self.name = name
    self.level_base = level_base
    self.multiplier = multiplier
    self.level_min = level_min
    self.allow_negative = allow_negative

static func get_(name: String) -> AttributeType:
    return _we[name]


func get_dynamic_level(level: int, multiplier: int = INT64_MIN) -> int:
    """ 无限范围的近似等比随机 """
    if multiplier == INT64_MIN:
        multiplier = self.multiplier
    var v: int = RandSys.rand.randi_range(0, multiplier)
    if v != 0: # 抽到当前level
        return level
    v = RandSys.rand.randi_range(0, multiplier + 1)
    var dir: int = 0
    if v == 0:                       # level抽到减少
        dir = -1
    elif v == multiplier + 1:        # level抽到增加
        dir = 1
    var level_changed: int = 0
    while true:
        level_changed += dir         # 记录level变化量
        v = RandSys.rand.randi_range(0, multiplier)  # 重新抽，但只往1个方向抽
        if v > 0:                    # 抽到偏移后的当前level
            break
    return level + level_changed

