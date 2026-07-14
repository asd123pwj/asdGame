class_name Sys
extends Node

static var sys: Sys
static var sys_cfg: SysCfg
static var randSys: RandSys
static var msgBus: MsgBus
static var timeSys: TimeSys
static var attrSys: AttrSys

static var USER_CONFIG_DIR := "user://Config/"
static var SYS_CONFIG_DIR := "res://Config/"
static var RESET := true

var _test = Test.new()

func _ready() -> void:
    sys = self
    init_sub_system()
    
    # print("test")
    _test.run()


func init_sub_system() -> void:
    sys_cfg = SysCfg.new()
    randSys = RandSys.new()
    msgBus = MsgBus.new()
    timeSys = TimeSys.new()
    attrSys = AttrSys.new()
    # print("init_done")
