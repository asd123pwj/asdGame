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
var inventories: Inventories
""" ----- Actor ----- """
var body: CharacterBody2D

static var _we: Dictionary[int, Character] = {}

var ID: int = get_instance_id()

func _init(archetype_type: String, name: String="") -> void:
    _we[ID] = self
    self.name = name if name != "" else archetype_type
    _init_from_archetype(archetype_type)

func physics_process(delta: float) -> void:
    skills.physics_process(delta)

func _init_from_archetype(archetype_type: String) -> void:
    var archetype: Archetype = Archetype.get_(archetype_type)
    create_body(archetype_type)
    attrs = Attributes.new(self, archetype.buffs)
    statuses = Statuses.new(self, archetype.statuses)
    behaviors = Behaviors.new(self, archetype.behaviors)
    interactions = Interactions.new(self, archetype.interactions)
    skills = Skills.new(self, archetype.skills)
    collisions = Collisions.new(self, archetype.collisions)
    inventories = Inventories.new(self, archetype.inventories)


func create_body(archetype_type: String) -> CharacterBody2D:
    var body_name: String = Archetype.get_(archetype_type).bodies[0]
    body = Body.get_(body_name).create()
    body.set_meta("character", self)
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(640, 128)
    return body




    