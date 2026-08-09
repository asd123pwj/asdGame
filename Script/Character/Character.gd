class_name Character
extends RefCounted


var name: String
""" ----- Logic ----- """
var attrs: Attributes
var statuses: Statuses
var behaviors: Behaviors
var interactions: Interactions
var skills: Skills
var collisions: Collisions
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
    var archetype: Archetype = Archetype.get_(race_name)
    body = _init_body(archetype.bodies[0])
    attrs = Attributes.new(self, archetype.buffs)
    statuses = Statuses.new(self, archetype.statuses)
    behaviors = Behaviors.new(self, archetype.behaviors)
    interactions = Interactions.new(self, archetype.interactions)
    skills = Skills.new(self, archetype.skills)
    collisions = Collisions.new(self, archetype.collisions)

func _init_body(body_name: String) -> CharacterBody2D:
    var body = Body.get_(body_name).create()
    body.set_meta("character", self)
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(640, 128)
    return body




    