class_name Race
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
# var types: Array[String]
var buffs: Array[String]
var statuses: Array[String]
var behaviors: Array[String]
var interactions: Array[String]
var bodies: Array[String]

""" ----- Global ----- """
static var _we: Dictionary[String, Race] = {}

func _init(
        config: Dictionary,
        # name: String, 
        # # types: Array=[], 
        # buffs: Array=[], 
        # statuses: Array=[],
        # behaviors: Array=[],
        # interactions: Array=[],
        # bodies: Array=[]
        ) -> void:
    self.name = config["name"]
    _we[name] = self
    
    self.buffs.assign(Utils.find_dict(config, ["buffs"], []))
    self.statuses.assign(Utils.find_dict(config, ["statuses"], []))
    self.behaviors.assign(Utils.find_dict(config, ["behaviors"], []))
    self.interactions.assign(Utils.find_dict(config, ["interactions"], []))
    self.bodies.assign(Utils.find_dict(config, ["bodies"], []))

    # self.name = name
    # self.types.assign(types.filter(func(x): return x is String))
    # self.buffs.assign(buffs.filter(func(x): return x is String))
    # self.statuses.assign(statuses.filter(func(x): return x is String))
    # self.behaviors.assign(behaviors.filter(func(x): return x is String))
    # self.interactions.assign(interactions.filter(func(x): return x is String))
    # self.bodies.assign(bodies.filter(func(x): return x is String))


static func get_(name: String) -> Race:
    return _we[name]
