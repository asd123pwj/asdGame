class_name Sys
extends Node
## 全局单例与总调度（挂在根场景上，见 Script/设计文档.md）。
## 职责：① 启动时按固定顺序 new 出所有子系统并放进 static 变量；
##       ② 把引擎回调（_input/_process/_physics_process）转发给对应系统。
## 被谁用：全项目都通过 `Sys.xxx` 拿子系统（Sys.uiSys / Sys.timeSys / Sys.sysCfg / …）。

## 自身实例（Node）。给"需要 Node 又拿不到静态上下文"的地方用（如 get_tree()）。
static var sys: Sys
## 系统配置（随机种子、目录、时辰周期…）。被谁用：RandSys / ShaderManager / TimeSys / ConfigBase / Attributes。
static var sysCfg: SysCfg
## 随机数系统。被谁用：需要随机的判定 `Sys.randSys.rand`。
static var randSys: RandSys
## 消息总线（按 ID 收发）。被谁用：MessageHub 的各 send_/listen_。
static var msgBus: MsgBus
## shader 表（文件名 → Shader）。被谁用：需要特效材质的地方。
static var shaders: ShaderManager
## 时间系统（年月日时 + 时辰推进）。被谁用：TimeFormat、状态的 time 监听。
static var timeSys: TimeSys
## 角色系统（生成/管理角色）。被谁用：Character 各处的 spawn/查询。
static var charSys: CharSys
## 预设注册器：new 它就等于触发 Config/ 全目录扫描注册。被谁用：仅启动时（见 init_sub_system）。
static var presets: PresetRegister
## 输入系统（方法都是静态的，这里只是持有实例）。被谁用：Sys._input / Sys._process。
static var inputSys: InputSys
## 地图系统。被谁用：MapSys.place/build 等。
static var tmapSys: MapSys
## 指令系统（解析并执行指令串）。被谁用：Msg.send_cmd。
static var cmdSys: CmdSys
## UI 系统（开启/登记 UI）。成员都是静态的，日常直接用 `UISys.xxx`；
## 这里的实例只用于启动时跑一次 `UISys._init()`（建 UI 根）。被谁用：Sys.init_sub_system。
static var uiSys: UISys

static var autoSys: AutoSys

## "SYS" 角色：世界默认值、系统级状态（如全局 Tick）挂在它身上。
## 被谁用：Attributes 取世界默认值、状态里以 SYS 为主体的判定。
static var sys_status: Character

## 配置目录与"是否重置配置"都不在这里：它们是常量，放在 SysCfg（Config/SystemConfig.gd）
## 的 `USER_CONFIG_DIR` / `SYS_CONFIG_DIR` / `RESET`——唯一使用者（ConfigBase / PresetRegister）
## 那边更近，而且常量不会有"静态变量取到空值"这类时序问题。

## 测试入口（见 Test）。被谁用：_ready。
var _test = Test.new()

## 启动：记下自身 → 起子系统 → 建 SYS 角色 → 跑测试。
## 被谁用：引擎（根场景就绪时）。
func _ready() -> void:
    sys = self
    init_sub_system()
    sys_status = CharSys.create_char("SYS", "SYS")
    print("test")
    _test.run()

## 引擎输入转发给输入系统。被谁用：引擎。
func _input(event: InputEvent) -> void:
    InputSys._input(event)

## 每帧顺序（不能换）：输入逐帧 HOLD → 时间推进（末尾 send_tick，逐帧状态在这里满足）
## → 帧末清空指针位移（等所有消费方用完）。
## 被谁用：引擎。
func _process(delta: float) -> void:
    InputSys._process(delta)
    TimeSys._process(delta)   # 末尾 send_tick()，逐帧状态（如 "Mouse Left | Tick"）在这里满足
    AutoSys._process(delta)
    # 指针位移的清零不在这儿：InputSys._process 末尾用 deferred 排到"帧末"自己清（见 InputSystem）

## 物理帧转发给角色系统（角色的物理相关行为）。被谁用：引擎。
func _physics_process(delta: float) -> void:
    CharSys._physics_process(delta)

## 按固定顺序初始化全部子系统；presets 放在最后之前是有意的——它一 new 就会扫描并注册所有预设。
## 被谁用：_ready。
func init_sub_system() -> void:
    sysCfg = SysCfg.new()
    cmdSys = CmdSys.new()
    randSys = RandSys.new()
    msgBus = MsgBus.new()
    autoSys = AutoSys.new()
    shaders = ShaderManager.new()
    timeSys = TimeSys.new()
    charSys = CharSys.new()
    presets = PresetRegister.new()
    inputSys = InputSys.new()
    tmapSys = MapSys.new()
    uiSys = UISys.new()
    # print("init_done")
