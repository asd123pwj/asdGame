class_name BehaviorSpawn 
extends RefCounted


func _init() -> void:
    pass

func spawn(race_name: String, name: String="") -> Character:
    var char_: Character = CharSys.spawn(race_name, name)
    return char_
