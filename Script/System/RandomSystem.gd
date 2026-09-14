class_name RandSys
extends BaseClass
## 随机数系统：全项目唯一的随机源（不要各处自己 new RandomNumberGenerator）。
## 种子来自系统配置，所以同一个 random_seed 每次跑出来的序列一致（可复现）。
## 被谁用：需要随机的地方 `Sys.randSys.rand.randi_range(...)` 等。

## 随机数发生器（用 SysCfg.random_seed 播种）。
## 被谁用：随机判定/随机取值的地方。
static var rand: RandomNumberGenerator = RandomNumberGenerator.new()

## 用配置里的种子做 hash 播种。
## 被谁用：Sys.init_sub_system。
func _init() -> void:
    rand.seed = hash(Sys.sysCfg.random_seed)
