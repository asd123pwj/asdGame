class_name SysCfg
extends ConfigBase

# ---- Tilemap 几何常量（统一集中管理，方便修改）----
const REGION_SIZE := Vector2i(48, 48)   # tile/P3D 图集区域尺寸
const GRID_SIZE := Vector2i(32, 32)     # 格子尺寸
const TILE_MARGINS := Vector2i(0, 0)    # 图集边距
const TILE_SEPARATION := Vector2i(0, 0) # 图集间隔
const P3D_OFFSET := Vector2(0, 16)      # P3D 精灵相对格子的偏移
const BLOCK_SIZE := 16                  # TilemapBlock 区块尺寸
const SHADERS_DIR := "res://Script/Shader/Shaders"  # shader 目录
const DEBUG_DIR := "res://Debug/"       # 调试输出目录（图集预处理结果等）
const P3D_TILE_ORIGIN := Vector2i(-8, 8) # # P3D 瓦片定位校正（texture_origin）。

var random_seed: String = "20230204"
var max_players: int = 10

var dao_init_value: Dictionary[Enums.ValueType, int] = {
    Enums.ValueType.BASE: 0,
    Enums.ValueType.MIN: INT64_MIN,
    Enums.ValueType.MULTIPLIER: 10,
}