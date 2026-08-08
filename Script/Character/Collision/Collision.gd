class_name Collision
extends PresetRegister


var name: String
var collision_name: String
var config: Array
var collision 

var collision_objs: Dictionary[Character, Variant] = {}

static var _we: Dictionary[String, Collision] = {}

func _init(name: String, collision_name: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.collision_name = collision_name
    self.config = config
    _get_collision_by_name()

func _get_collision_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == collision_name:
            collision = load(cls["path"])
            return
    push_error("找不到类: ", collision_name)
    collision = null

static func get_(name: String) -> Collision:
    return _we[name]

func listen(char_: Character) -> void:
    @warning_ignore("unsafe_method_access")
    collision_objs[char_] = collision.new(char_, name, config)
