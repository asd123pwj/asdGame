class_name SystemShortcutPreset
extends PresetRegister
## 系统快捷：依赖某状态满足后，直接执行指令系统的指令。
## 比 Interaction 更简单——不做属性/背包操作，只把 config 里的指令串丢给 Msg.send_cmd。


var name: String
## 依赖状态名（支持 "状态名@unique_name" 定向到独特角色，见 Msg._resolve_target）
var dependence_status: String
## 要执行的指令串（可含多条，'\v' 分隔，语义同 CmdSys）
var config: String

static var _we: Dictionary[String, SystemShortcutPreset] = {}
# {Char: {msg_ID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

func _init(name: String, dependence_status: String, config: String = "") -> void:
    _we[name] = self
    self.name = name
    self.dependence_status = dependence_status
    self.config = config

static func get_(name: String) -> SystemShortcutPreset:
    return _we[name]

func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        Msg.send_cmd(config)
        Msg.send_shortcut_act(char_, name)
    var msg_ID = Msg.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
