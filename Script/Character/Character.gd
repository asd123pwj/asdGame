class_name Character
extends BaseClass


var name: String
""" ----- Logic ----- """
var attrs: Attributes
var statuses: Statuses
# var behaviors: Behaviors
var interactions: Interactions
var skills: Skills
var collisions: Collisions
var inventories: Inventories
var shortcuts: SystemShortcuts
""" ----- Actor ----- """
var body: CharacterBody2D = null
var archetype_type: String = ""
var unique_name: String = ""
var _body_created: bool = false

static var _we: Dictionary[int, Character] = {}


func _init(archetype_type: String, name: String="", unique_name: String="") -> void:
    _we[ID] = self
    self.name = name if name != "" else archetype_type
    self.unique_name = unique_name
    if unique_name != "":
        CharSys.bind_unique(unique_name, self)
    _init_from_archetype(archetype_type)
    init_done()

static func get_(id: int) -> Character:
    return _we[id]

func physics_process(delta: float) -> void:
    skills.physics_process(delta)

func _init_from_archetype(archetype_type: String) -> void:
    self.archetype_type = archetype_type
    var archetype: Archetype = Archetype.get_(archetype_type)
    attrs = Attributes.new(self, archetype.buffs)
    statuses = Statuses.new(self, archetype.statuses)
    # behaviors = Behaviors.new(self, archetype.behaviors)
    interactions = Interactions.new(self, archetype.interactions)
    skills = Skills.new(self, archetype.skills)
    collisions = Collisions.new(self, archetype.collisions)
    inventories = Inventories.new(self, archetype.inventories)
    shortcuts = SystemShortcuts.new(self, archetype.shortcuts)

func init_done() -> void:
    statuses.char_init_done()

## body 延后生成：首次需要时创建；archetype 未配 bodies 则留空返回 null
func ensure_body() -> CharacterBody2D:
    if _body_created:
        return body
    _body_created = true
    var bodies: Array[String] = Archetype.get_(archetype_type).bodies
    if bodies.is_empty():
        return null
    var body_name: String = bodies[0]
    body = BodyPreset.get_(body_name).create()
    body.set_meta("character", self)
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(640, 128)
    @warning_ignore("unsafe_method_access")
    collisions.attach_collisions()
    return body




    