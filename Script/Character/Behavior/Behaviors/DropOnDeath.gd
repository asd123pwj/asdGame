class_name DropOnDeath
extends RefCounted


static func act(_char: Character, _config: Array) -> void:
    var races = _config
    for race in races:
        CharSys.spawn(race)
    