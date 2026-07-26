class_name Character
extends RefCounted


var name: String
var attrs: Attributes
var statuses: Statuses
var behaviors: Behaviors
var interactions: Interactions
var ID: int = get_instance_id()

func _init(race_name: String, name: String="") -> void:
    self.name = name if name != "" else race_name
    _init_as_race(race_name)

func _init_as_race(race_name: String) -> void:
    var race_type: Race = Race.get_(race_name)
    attrs = Attributes.new(self, race_type.buffs)
    statuses = Statuses.new(self, race_type.statuses)
    behaviors = Behaviors.new(self, race_type.behaviors)
    interactions = Interactions.new(self, race_type.interactions)

    



    