class_name Sys
extends Node

static var sys: Sys
static var sysCfg: SysCfg
static var randSys: RandSys
static var msgBus: MsgBus
static var timeSys: TimeSys
static var charSys: CharSys
static var presets: PresetRegister

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
    sysCfg = SysCfg.new()
    randSys = RandSys.new()
    msgBus = MsgBus.new()
    timeSys = TimeSys.new()
    charSys = CharSys.new()
    presets = PresetRegister.new()
    # print("init_done")
