class_name SysCfg
extends ConfigBase

## ---- 配置目录（全项目读写 json 的路径只在这里，而且是**常量**：不存在"取到空值"的时序问题）----
## 用户配置目录（存盘位置）。被谁用：ConfigBase（唯一读写 json 的地方，按"类名.json"找）。
## 放项目内的 `res://tmp/Config/`：RESET=true 时每次启动都会重新生成一份，属于**可随时删的产物**，
## 放项目里方便对照代码看，又不至于把 json 堆在根目录（`tmp/` 已在 .gitignore 里）。
## 若以后 RESET=false、要长期保留用户改动，把它改回 `user://Config/` 更合适。
## 必须留在 `res://` / `user://` 下：拼路径时若是相对路径，文件会落到项目根目录
## （就是"项目根莫名多出一堆配置 json"那个坑；ConfigBase._init 另有一道兜底校验）。
const USER_CONFIG_DIR := "res://tmp/Config/"
## 系统配置目录（代码里的预设来源）。被谁用：PresetRegister._scan。
const SYS_CONFIG_DIR := "res://Config/"
## 是否每次启动都用代码里的 values 重写用户配置（true = 不读旧 json）。
## 被谁用：ConfigBase.save_or_init。
## 注意：对"已存盘的枚举整数"也有效——Enums 里改枚举时新值只能追加（插在中间会让旧 json 里的值串位）。
const RESET := true


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

# ---- 动作流水（ActionHistory）的限流：某个动作在 history_window 秒内超过 history_window_max 次之后，
#      **每秒只记第一次**（一直这么算，直到它安静 history_window 秒才复位计数）。
#      n / m 两个参数就这两个；再改就改这儿，别在调用方各写一遍。
#      为什么要它：技能是每物理帧都在执行的，不限流的话流水会被写爆、界面也会一秒跳 60 次。
var history_window := 5.0
var history_window_max := 10




"""
░████   ░██ ░██ 
░██░██  ░██ ░██ 
░██ ░██ ░██ ░██ 
░██ ░██ ░██ ░██ 
░██ ░██ ░██ ░██ 
░██ ░██  ░██░██  
"""
# ---- UI 交互参数（集中在这里，不要在 UIInteract 里写死）----
static var resize_min_scale := 0.2      # 等比缩放的下限（拖再狠也不会缩成 0）
static var resize_max_scale := 5.0      # 等比缩放的上限（拖再狠也不会涨到天上去）
static var rescale_epsilon := 0.001     # 缩放里"上帧距离"作除数时的保护下限

# 找"当底的 stylebox 槽"时的顺序：哪个控件有哪个就用哪个（见 UIBase._background_slot）。
static var ui_background_slots: Array[String] = ["panel", "normal", "background"]

# ---- UI 字号 ----
# **默认字号，同时也是最小字号**（见 UIBase.reapply）：没配 `font_size` 的元素就用它；
# 配了比它小的也**抬到它**——"小到看不清"的界面没法用，要更小就改这里，别在配置里各写各的（改了也不生效）。
# 16 = Godot 默认主题的字号（所以"没配"的元素看起来和以前一样）。
static var ui_font_size_default := 16
