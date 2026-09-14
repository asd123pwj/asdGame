class_name SystemShortcutPreset
extends PresetRegister
## 系统快捷：依赖某状态满足后，直接执行指令系统的指令。
## 比 Interaction 更简单——不做属性/背包操作，只把 config 里的指令串丢给 Msg.send_cmd。
## 被谁用：SystemShortcuts.add_shortcut（装到角色身上）、Archetype 的 shortcuts 字段。


## 预设名（唯一）。被谁用：SystemShortcuts 的字典键与广播。
var name: String
## 依赖状态名（支持 "状态名@identity" 定向到独特角色，见 Msg._resolve_target）
var dependence_status: String
## 要执行的指令串（可含多条，'\v' 分隔，语义同 CmdSys）
var config: String

## 全部预设：名 -> 实例。被谁用：SystemShortcutPreset.get_。
static var _we: Dictionary[String, SystemShortcutPreset] = {}
# {Char: {msg_ID: func}}
## 每个角色各自登记的触发函数（用于 unlisten）。被谁用：listen/unlisten。
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

## 注册一条快捷预设。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, dependence_status: String, config: String = "") -> void:
    _we[name] = self
    self.name = name
    self.dependence_status = dependence_status
    self.config = config

## 按名取预设。被谁用：SystemShortcuts.add_shortcut。
static func get_(name: String) -> SystemShortcutPreset:
    return _we[name]

## 给某角色登记触发：依赖状态满足 → 执行指令串（并广播"快捷触发"）。
## 被谁用：SystemShortcuts.add_shortcut。
func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        Msg.send_cmd(config)
        Msg.send_shortcut_act(char_, name)
    var msg_ID = Msg.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

## 退订该角色的触发函数。被谁用：SystemShortcuts.remove_shortcut。
func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
