class_name CharSys
extends RefCounted


func _init() -> void:
    pass
    # PresetRegister.register(AttributeType)
    # PresetRegister.register(AttributeBuff)
    # PresetRegister.register(AttributeRelation)
    # PresetRegister.register(AttributeSet)
    # PresetRegister.register(StatusType)
    # PresetRegister.register(RaceType)

static func spawn(race_name: String, name: String="") -> Character:
    var char_: Character = Character.new(race_name, name)
    MsgHubSys.send_spawn(char_)
    return char_