class_name CharSys
extends RefCounted


func _init() -> void:
    PresetRegister.register(AttributeType)
    PresetRegister.register(AttributeBuff)
    PresetRegister.register(AttributeRelation)
    PresetRegister.register(AttributeSet)
    PresetRegister.register(StatusType)
    PresetRegister.register(RaceType)

static func spawn(name: String, race_name: String) -> Character:
    var char_: Character = Character.new(name, race_name)
    MsgHubSys.send_spawn(char_)
    return char_