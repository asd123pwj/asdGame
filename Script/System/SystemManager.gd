class_name Sys
extends Node

static var sys: Sys
static var sysCfg: SysCfg
static var randSys: RandSys
static var msgBus: MsgBus
static var shaders: ShaderManager
static var timeSys: TimeSys
static var charSys: CharSys
static var presets: PresetRegister
static var inputSys: InputSys
static var tmapSys: TMapSys

static var USER_CONFIG_DIR := "user://Config/"
static var SYS_CONFIG_DIR := "res://Config/"
static var RESET := true

var _test = Test.new()

func _ready() -> void:
    sys = self
    init_sub_system()
    
    print("test")
    _test.run()

func _input(event: InputEvent) -> void:
    InputSys._input(event)

func _process(delta: float) -> void:
    InputSys._process(delta)

func _physics_process(delta: float) -> void:
    CharSys._physics_process(delta)

func init_sub_system() -> void:
    sysCfg = SysCfg.new()
    randSys = RandSys.new()
    msgBus = MsgBus.new()
    shaders = ShaderManager.new()
    timeSys = TimeSys.new()
    charSys = CharSys.new()
    presets = PresetRegister.new()
    inputSys = InputSys.new()
    tmapSys = TMapSys.new()
    # print("init_done")
