class_name InteractionPreset
extends PresetRegister


var name: String
var interaction_name: String
var dependence_status: String
var config
var interaction 

static var _we: Dictionary[String, InteractionPreset] = {}
# {Char: {msg_ID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

func _init(name: String, interaction_name: String, dependence_status: String, config = null) -> void:
    _we[name] = self
    self.name = name
    self.interaction_name = interaction_name
    self.dependence_status = dependence_status
    self.config = config
    _get_interaction_by_name()

func _get_interaction_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == interaction_name:
            @warning_ignore("unsafe_method_access")
            interaction = load(cls["path"]).new()
            return
    push_error("找不到类: ", interaction_name)
    interaction = null

static func get_(name: String) -> InteractionPreset:
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
