class_name RandomSystem
extends RefCounted

static var rand: RandomNumberGenerator

func _init() -> void:
    rand = RandomNumberGenerator.new()
    rand.seed = hash(Sys.sys_cfg.random_seed)
