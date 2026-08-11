class_name DropOnDeath
extends BehaviorBase


func act(_char: Character, _config: Array) -> Enums.Code:
    var races: Array = _config
    for race in races:
        CharSys.spawn(race)
    return Enums.Code.OK
    