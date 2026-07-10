class_name Sys
extends Node

static var sys: Sys
static var sys_cfg: SystemConfig
static var randSys: RandomSystem
static var msgBus: MessageBus
static var timeSys: TimeSystem
static var attrSys: AttributeSystem

var _test = Test.new()

func _ready() -> void:
    sys = self
    init_sub_system()
    
    # print("test")
    _test.run()


func init_sub_system() -> void:
    sys_cfg = SystemConfig.new()
    randSys = RandomSystem.new()
    msgBus = MessageBus.new()
    timeSys = TimeSystem.new()
    attrSys = AttributeSystem.new()
    # print("init_done")
