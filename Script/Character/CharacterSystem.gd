class_name CharSys
extends RefCounted


func _init() -> void:
    PresetRegister.register(AttributeType)
    PresetRegister.register(AttributeBuff)
    PresetRegister.register(AttributeRelation)
    PresetRegister.register(AttributeSet)
    PresetRegister.register(StatusType)
    PresetRegister.register(RaceType)