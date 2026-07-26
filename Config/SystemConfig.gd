class_name SysCfg
extends ConfigBase

var random_seed: String = "20230204"
var max_players: int = 10

var dao_init_value: Dictionary[Enums.ValueType, int] = {
    Enums.ValueType.BASE: 0,
    Enums.ValueType.MIN: INT64_MIN,
    Enums.ValueType.MULTIPLIER: 10,
}