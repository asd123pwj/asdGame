class_name Interaction
extends PresetRegister


var name: String
var dependence_status: String
var config: Array
var interaction 

static var _we: Dictionary[String, Interaction] = {}
# {Char: {msg_ID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

func _init(name: String, dependence_status: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.dependence_status = dependence_status
    self.config = config
    _get_interaction_by_name()

func _get_interaction_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == name:
            interaction = load(cls["path"])
            return
    push_error("找不到类: ", name)
    interaction = null

static func get_(name: String) -> Interaction:
    return _we[name]

func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        # 之前想着以_msg作为target，结果发现status监听不到target，_msg不可能是target
        # 所以改为了去读取target，
        var target = MsgHubChar.get_status_detected(char_, dependence_status)
        @warning_ignore("unsafe_method_access")
        interaction.interact(char_, target, config)
        MsgHubChar.send_interaction_interact(char_, name)
    var msg_ID = MsgHubChar.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
