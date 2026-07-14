class_name RandSys
extends RefCounted

static var rand: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
    rand.seed = hash(Sys.sys_cfg.random_seed)
