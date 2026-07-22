class_name BehaviorType
extends PresetRegister


var name: String
var dependence_status: String
var config: Array
var behavoir #: BehaviorBase

static var _we: Dictionary[String, BehaviorType] = {}
# {Char: {msg_ID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

func _init(name: String, dependence_status: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.dependence_status = dependence_status
    self.config = config
    _get_behavoir_by_name()

func _get_behavoir_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == name:
            behavoir = load(cls["path"])
            return
    push_error("找不到类: ", name)
    behavoir = null

static func get_(name: String) -> BehaviorType:
    return _we[name]

func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        @warning_ignore("unsafe_method_access")
        behavoir.act(char_, config)
        MsgHubChar.send_behavior_act(char_, name)
    var msg_ID = MsgHubChar.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
