class_name BehaviorType
extends PresetRegister


var name: String
var dependence_status: String
var config: Array = []

static var _we: Dictionary[String, BehaviorType] = {}

func _init(name: String, dependence_status: String, config: Array) -> void:
    self.name = name
    self.dependence_status = dependence_status
    self.config = config
    _we[name] = self

static func get_(name: String) -> BehaviorType:
    return _we[name]

func listen(char_: Character) -> void:
    MsgHubChar.listen_status_satisfied(char_, dependence_status, act)

func act(_msg) -> void:
    DropOnDeath.new(config)

