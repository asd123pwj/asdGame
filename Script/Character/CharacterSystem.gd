class_name CharSys
extends BaseClass

var pool: Array = []

func _init() -> void:
    pass

static func _physics_process(delta: float) -> void:
    for char_: Character in Character._we.values():
        char_.physics_process(delta)

static func spawn(race_name: String, name: String="") -> Character:
    var char_: Character = create_char(race_name, name)
    # char_.create_body()
    Msg.send_spawn(char_)
    return char_

static func create_char(race_name: String, name: String="") -> Character:
    var char_: Character = Character.new(race_name, name)
    Msg.send_char_create(char_)
    return char_