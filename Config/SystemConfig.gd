class_name SysCfg
extends ConfigBase



var random_seed: String = "20230204"
var max_players: int = 10

var dao_init_value: Dictionary[Enums.ValueType, int] = {
    Enums.ValueType.BASE: 0,
    Enums.ValueType.MIN: INT64_MIN,
    Enums.ValueType.MULTIPLIER: 10,
}


"""
░███     ░███                       
░████   ░████                       
░██░██ ░██░██  ░██████   ░████████  
░██ ░████ ░██       ░██  ░██    ░██ 
░██  ░██  ░██  ░███████  ░██    ░██ 
░██       ░██ ░██   ░██  ░███   ░██ 
░██       ░██  ░█████░██ ░██░█████  
                         ░██        
                         ░██        
"""
# ---- Tilemap 几何常量（统一集中管理，方便修改）----
var REGION_SIZE := Vector2i(48, 48)   # tile/P3D 图集区域尺寸
const GRID_SIZE := Vector2i(32, 32)     # 格子尺寸
var TILE_MARGINS := Vector2i(0, 0)    # 图集边距
var TILE_SEPARATION := Vector2i(0, 0) # 图集间隔
var P3D_OFFSET := Vector2(0, 16)      # P3D 精灵相对格子的偏移
var BLOCK_SIZE := 16                  # TilemapBlock 区块尺寸
var SHADERS_DIR := "res://Script/Shader/Shaders"  # shader 目录
var DEBUG_DIR := "res://Debug/"       # 调试输出目录（图集预处理结果等）
var P3D_TILE_ORIGIN := Vector2i(-8, 8) # # P3D 瓦片定位校正（texture_origin）。


"""
░███     ░███                                  
░████   ░████                                  
░██░██ ░██░██  ░███████  ░██    ░██  ░███████  
░██ ░████ ░██ ░██    ░██ ░██    ░██ ░██    ░██ 
░██  ░██  ░██ ░██    ░██  ░██  ░██  ░█████████ 
░██       ░██ ░██    ░██   ░██░██   ░██        
░██       ░██  ░███████     ░███     ░███████  
                                               
"""
var gravity := 1000
var min_damping_velocity := Vector2(100.0, 100.0)



"""
  ░██████                         ░██ 
 ░██   ░██                        ░██ 
░██        ░█████████████   ░████████ 
░██        ░██   ░██   ░██ ░██    ░██ 
░██        ░██   ░██   ░██ ░██    ░██ 
 ░██   ░██ ░██   ░██   ░██ ░██   ░███ 
  ░██████  ░██   ░██   ░██  ░█████░██ 
"""
# 命令系统懒注册，
# 为false时，在游戏启动时注册所有命令，这个会拖慢启动速度和内存占用，但这点资源也许无关紧要
# 为true时，在第一次调用命令时注册命令，随用随取，带缓存
var lazy_command_registration := false

# 命令解析/执行缓存，
# 为true时，缓存命令的"解析计划"（含 $ 表达式的定位过程）与组装好的参数，重复调用时跳过解析计算；
# 为false时，每条命令每次都重新解析，便于对比测试或排查"缓存导致状态不更新"的问题
var cache_command := true

# 命令缓存 L1（热缓存）容量：LRU 双向链表，满则把最久未用的降级到 L2
var cache_command_l1_capacity := 256

# 命令缓存 L2（温缓存）存活时间（秒）：用"时钟指针 + 时间桶"实现 O(1) 过期——
# 桶数 = ceil(TTL / 周期)，每隔一个周期指针前进一格并清空该桶（即淘汰最旧一批）
var cache_command_l2_ttl := 300.0

# 命令缓存 L2 的轮转周期（秒）：越小过期越精确、桶越多；越大越省，过期粒度越粗
var cache_command_l2_period := 30.0

# 命令缓存 L2 总量上限（条目数）：写入时若达上限，则强推指针清一格腾位，避免缓存无限膨胀
var cache_command_max := 1024





"""
░██████████   ░██                              
    ░██                                        
    ░██       ░██   ░█████████████   ░███████  
    ░██       ░██   ░██   ░██   ░██ ░██    ░██ 
    ░██       ░██   ░██   ░██   ░██ ░█████████ 
    ░██       ░██   ░██   ░██   ░██ ░██        
    ░██       ░██   ░██   ░██   ░██  ░███████  
"""
# 游戏时间周期：每经过 hour_period 秒，TimeSys 推进一个时辰
var hour_period := 2.0
