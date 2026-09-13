class_name CharSys
extends BaseClass

var pool: Array = []

## 独特角色字典：identity -> Character
## 供状态名 "状态名@identity" 定向到某独特角色（如"敌人"、"目标"）
## 绑定时机：初始化时（identity 非空），或运行时用 bind_identity 动态指向新角色
static var identities: Dictionary[String, Character] = {}

func _init() -> void:
    pass

static func _physics_process(delta: float) -> void:
    for char_: Character in Character._we.values():
        char_.physics_process(delta)

static func spawn(race_name: String, identity: String="", name: String="") -> Character:
    var char_: Character = create_char(race_name, identity, name)
    char_.ensure_body()
    Msg.send_spawn(char_)
    return char_

static func create_char(race_name: String, identity: String="", name: String="") -> Character:
    var char_: Character = Character.new(race_name, identity, name)
    Msg.send_char_create(char_)
    return char_

static func bind_identity(identity: String, char_: Character) -> void:
    identities[identity] = char_
    # identity 出现/换角色：把绑定到它的接收器迁到该角色对应的新节点
    # （这样"先监听、后出现"与"换角色"都能继续生效）
    MsgBus.rebind_identity(identity, char_)

static func get_identity(identity: String) -> Character:
    return identities.get(identity, null)