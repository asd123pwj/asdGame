class_name CharSys
extends RefCounted


func _init() -> void:
    pass

static func _physics_process(delta: float) -> void:
    for char_ in Character._we.values():
        char_.physics_process(delta)

static func spawn(race_name: String, name: String="") -> Character:
    var char_: Character = Character.new(race_name, name)
    MsgHubSys.send_spawn(char_)
    return char_