class_name Archetype
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
var collisions: Array[String]
var packages: Array[String]
var _unpacked: bool = false

""" ----- Global ----- """
static var _we: Dictionary[String, Archetype] = {}

func _init(config: Dictionary) -> void:
    self.name = config["name"]
    _we[name] = self
    
    self.buffs.assign(Utils.find_dict(config, ["buffs"], []))
    self.statuses.assign(Utils.find_dict(config, ["statuses"], []))
    self.behaviors.assign(Utils.find_dict(config, ["behaviors"], []))
    self.interactions.assign(Utils.find_dict(config, ["interactions"], []))
    self.bodies.assign(Utils.find_dict(config, ["bodies"], []))
    self.skills.assign(Utils.find_dict(config, ["skills"], []))
    self.collisions.assign(Utils.find_dict(config, ["collisions"], []))
    self.packages.assign(Utils.find_dict(config, ["packages"], []))

static func get_(name: String) -> Archetype:
    var archetype: Archetype = _we[name]
    if archetype._unpacked:
        return archetype
    archetype._unpacked = true
    if not archetype.packages.is_empty():
        for package in archetype.packages:
            var content = get_(package)
            archetype.buffs.append_array(content.buffs)
            archetype.statuses.append_array(content.statuses)
            archetype.behaviors.append_array(content.behaviors)
            archetype.interactions.append_array(content.interactions)
            archetype.bodies.append_array(content.bodies)
            archetype.skills.append_array(content.skills)
            archetype.collisions.append_array(content.collisions)
        # 去重
        archetype.buffs.assign(_deduplicate(archetype.buffs))
        archetype.statuses.assign(_deduplicate(archetype.statuses))
        archetype.behaviors.assign(_deduplicate(archetype.behaviors))
        archetype.interactions.assign(_deduplicate(archetype.interactions))
        archetype.bodies.assign(_deduplicate(archetype.bodies))
        archetype.skills.assign(_deduplicate(archetype.skills))
        archetype.collisions.assign(_deduplicate(archetype.collisions))
    return archetype


static func _deduplicate(arr: Array) -> Array:
    var result: Dictionary = {}
    for item in arr:
        result[item] = true  
    return result.keys()

