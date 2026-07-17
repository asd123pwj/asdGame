class_name RandSys
extends RefCounted

static var rand: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
    rand.seed = hash(Sys.sysCfg.random_seed)
