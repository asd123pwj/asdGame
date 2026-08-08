class_name Race
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var buffs: Array[String]
var statuses: Array[String]
var behaviors: Array[String]
var interactions: Array[String]
var bodies: Array[String]
var skills: Array[String]

""" ----- Global ----- """
static var _we: Dictionary[String, Race] = {}

func _init(config: Dictionary) -> void:
    self.name = config["name"]
    _we[name] = self
    
    self.buffs.assign(Utils.find_dict(config, ["buffs"], []))
    self.statuses.assign(Utils.find_dict(config, ["statuses"], []))
    self.behaviors.assign(Utils.find_dict(config, ["behaviors"], []))
    self.interactions.assign(Utils.find_dict(config, ["interactions"], []))
    self.bodies.assign(Utils.find_dict(config, ["bodies"], []))
    self.skills.assign(Utils.find_dict(config, ["skills"], []))

static func get_(name: String) -> Race:
    return _we[name]
