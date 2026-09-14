class_name CharSys
extends BaseClass
## 角色系统：角色的生成入口与身份表（见 Script/Character/Character.md）。
## 被谁用：Sys.charSys（全局）；Character._init 会回调 bind_identity。

## 角色池（当前未使用，占位）。
var pool: Array = []

## 独特角色字典：identity -> Character
## 供状态名 "状态名@identity" 定向到某独特角色（如"敌人"、"目标"）
## 绑定时机：初始化时（identity 非空），或运行时用 bind_identity 动态指向新角色
static var identities: Dictionary[String, Character] = {}

func _init() -> void:
    pass

## 逐帧驱动所有角色的物理（技能队列在这里跑）。被谁用：Sys._physics_process。
static func _physics_process(delta: float) -> void:
    for char_: Character in Character._we.values():
        char_.physics_process(delta)

## 生成一个"有身体"的角色：建角色 → 建身体 → 广播生成消息。
## 被谁用：需要可见/可碰撞角色的地方（Test.run、指令）。
static func spawn(race_name: String, identity: String="", name: String="") -> Character:
    var char_: Character = create_char(race_name, identity, name)
    char_.ensure_body()
    Msg.send_spawn(char_)
    return char_

## 只建逻辑角色（不建身体，如 SYS 这类纯逻辑角色）。
## 被谁用：spawn、Sys._ready（建 SYS 角色）。
static func create_char(race_name: String, identity: String="", name: String="") -> Character:
    var char_: Character = Character.new(race_name, identity, name)
    Msg.send_char_create(char_)
    return char_

## 登记/改绑 identity 指向的角色，并把"绑定到该 identity 的消息接收器"迁到新角色。
## 被谁用：Character._init（identity 非空）、换角色（重生）流程。
static func bind_identity(identity: String, char_: Character) -> void:
    identities[identity] = char_
    # identity 出现/换角色：把绑定到它的接收器迁到该角色对应的新节点
    # （这样"先监听、后出现"与"换角色"都能继续生效）
    MsgBus.rebind_identity(identity, char_)

## 按 identity 取角色（没有返回 null）。
## 被谁用：Msg._resolve_target（"状态名@identity" 定向）。
static func get_identity(identity: String) -> Character:
    return identities.get(identity, null)
