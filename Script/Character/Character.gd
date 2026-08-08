class_name Character
extends RefCounted


var name: String
""" ----- Logic ----- """
var attrs: Attributes
var statuses: Statuses
var behaviors: Behaviors
var interactions: Interactions
var skills: Skills
""" ----- Actor ----- """
var body: CharacterBody2D

static var _we: Dictionary[int, Character] = {}

var ID: int = get_instance_id()

func _init(race_name: String, name: String="") -> void:
    _we[ID] = self
    self.name = name if name != "" else race_name
    _init_as_race(race_name)

func physics_process(delta: float) -> void:
    skills.physics_process(delta)

func _init_as_race(race_name: String) -> void:
    var race: Race = Race.get_(race_name)
    attrs = Attributes.new(self, race.buffs)
    statuses = Statuses.new(self, race.statuses)
    behaviors = Behaviors.new(self, race.behaviors)
    interactions = Interactions.new(self, race.interactions)
    skills = Skills.new(self, race.skills)
    body = _init_body(race.bodies[0])

func _init_body(body_name: String) -> CharacterBody2D:
    var body = Body.get_(body_name).create()
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(640, 128)
    return body




    