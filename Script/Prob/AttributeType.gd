class_name AttributeType
extends RefCounted


""" ----- individual ----- """
var type_name: String
var level_base: int
var level_min: bool 
var multiplier: int
## 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
var allow_negative: bool

""" ----- Global ----- """
static var _we: Dictionary[String, AttributeType] = {}

## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
func _init(
        type_name: String,
        level_base: int, 
        multiplier: int,
        level_min: int = INT64_MIN,
        allow_negative: bool = true 
        ) -> void:
    self.type_name = type_name
    self.level_base = level_base
    self.multiplier = multiplier
    self.level_min = level_min
    self.allow_negative = allow_negative
    _we[type_name] = self


static func get_(type: String) -> AttributeType:
    return _we[type]
    




""" ---------- Init ---------- """

func get_random_level(level: int, multiplier: int = INT64_MIN) -> int:
    """ 无限范围的近似等比随机 """
    if multiplier == INT64_MIN:
        multiplier = self.multiplier
    var v: int = Sys.randSys.rand.randi_range(0, multiplier)
    if v != 0: # 抽到当前level
        return level
    v = Sys.randSys.rand.randi_range(0, multiplier + 1)
    var dir: int = 0
    if v == 0:                       # level抽到减少
        dir = -1
    elif v == multiplier + 1:        # level抽到增加
        dir = 1
    var level_changed: int = 0
    while true:
        level_changed += dir         # 记录level变化量
        v = Sys.randSys.rand.randi_range(0, multiplier)  # 重新抽，但只往1个方向抽
        if v > 0:                    # 抽到偏移后的当前level
            break
    return level + level_changed
