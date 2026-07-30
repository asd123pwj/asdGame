class_name Character
extends RefCounted


var name: String
""" ----- Logic ----- """
var attrs: Attributes
var statuses: Statuses
var behaviors: Behaviors
var interactions: Interactions
""" ----- Actor ----- """
var actor: Actor
var ID: int = get_instance_id()

func _init(race_name: String, name: String="") -> void:
    self.name = name if name != "" else race_name
    _init_as_race(race_name)


func _init_as_race(race_name: String) -> void:
    var race: Race = Race.get_(race_name)
    attrs = Attributes.new(self, race.buffs)
    statuses = Statuses.new(self, race.statuses)
    behaviors = Behaviors.new(self, race.behaviors)
    interactions = Interactions.new(self, race.interactions)
    actor = Actor.new(self, race.bodies[0])




    