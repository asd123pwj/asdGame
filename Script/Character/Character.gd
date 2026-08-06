class_name Character
extends RefCounted


var name: String
""" ----- Logic ----- """
var attrs: Attributes
var statuses: Statuses
var behaviors: Behaviors
var interactions: Interactions
""" ----- Actor ----- """
var body: CharacterBody2D

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
    body = _init_body(race.bodies[0])

func _init_body(body_name: String) -> CharacterBody2D:
    var body = Body.get_(body_name).create()
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(128, 128)
    return body




    