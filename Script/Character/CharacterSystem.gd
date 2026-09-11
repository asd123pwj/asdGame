class_name CharSys
extends BaseClass

var pool: Array = []

## 独特角色字典：unique_name -> Character
## 供状态名 "状态名@unique_name" 定向到某独特角色（如"敌人"、"目标"）
## 绑定时机：初始化时（unique_name 非空），或运行时用 bind_unique 动态指向新角色
static var unique: Dictionary[String, Character] = {}

func _init() -> void:
    pass

static func _physics_process(delta: float) -> void:
    for char_: Character in Character._we.values():
        char_.physics_process(delta)

static func spawn(race_name: String, name: String="", unique_name: String="") -> Character:
    var char_: Character = create_char(race_name, name, unique_name)
    char_.ensure_body()
    Msg.send_spawn(char_)
    return char_

static func create_char(race_name: String, name: String="", unique_name: String="") -> Character:
    var char_: Character = Character.new(race_name, name, unique_name)
    Msg.send_char_create(char_)
    return char_

static func bind_unique(unique_name: String, char_: Character) -> void:
    unique[unique_name] = char_

static func get_by_unique(unique_name: String) -> Character:
    return unique.get(unique_name, null)