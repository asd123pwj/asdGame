class_name DropOnDeath
extends RefCounted




func _init(races: Array) -> void:
    for race in races:
        CharSys.spawn(race)
    