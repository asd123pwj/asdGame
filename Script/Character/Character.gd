class_name Character
extends RefCounted


var name: String
var attr: Attribute
var status: Status
var behavior: Behavior
var ID: int = get_instance_id()

func _init(race_name: String, name: String="") -> void:
    self.name = name if name != "" else race_name
    _init_as_race(race_name)

func _init_as_race(race_name: String) -> void:
    var race_type: RaceType = RaceType.get_(race_name)
    attr = Attribute.new(self, race_type.types, race_type.buffs)
    status = Status.new(self, race_type.statuses)
    behavior = Behavior.new(self, race_type.behaviors)
    



    