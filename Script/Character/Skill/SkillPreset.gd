class_name SkillPreset
extends PresetRegister
## 技能预设：依赖状态"满足/不满足"决定把技能放进执行队列还是移出（逐帧行为）。
## 被谁用：Skills.add_skill（装到角色身上）、Archetype 的 skills 字段。

## 预设名（唯一）。被谁用：Skills 的字典键与广播。
var name: String
## 实现类名（SkillBase 子类，如 "Skill_Walk"）。被谁用：_get_skill_by_name。
var skill_name: String
## 依赖的状态名（支持 "状态名@identity" 定向）。被谁用：listen。
var dependence_status: String
## 传给技能的参数（如速度）。被谁用：listen（进出队列时传给技能）。
var config: Array
## 实现类实例（**每个预设一个**）。被谁用：listen。
var skill: SkillBase

## 全部预设：名 -> 实例。被谁用：SkillPreset.get_。
static var _we: Dictionary[String, SkillPreset] = {}
# {Char: {msg_ID: func}}
## 每个角色各自登记的触发函数（用于 unlisten）。被谁用：listen/unlisten。
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

## 注册一条技能预设，并按类名实例化实现类。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, skill_name:String, dependence_status: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.skill_name = skill_name
    self.dependence_status = dependence_status
    self.config = config
    _get_skill_by_name()

## 按类名从全局类表取实现类并 new（取不到报错）。
## 被谁用：_init。
func _get_skill_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == skill_name:
            @warning_ignore("unsafe_method_access")
            skill = load(cls["path"]).new()
            return
    push_error("找不到Skill: ", skill_name)
    skill = null

## 按名取预设。被谁用：Skills.add_skill。
static func get_(name: String) -> SkillPreset:
    return _we[name]

## 给某角色登记：依赖状态"满足 → 入队"、"不满足 → 出队"，最后再按当前状态补一次（用 deferred，
## 避免在装配过程中同步改队列）。
## 被谁用：Skills.add_skill。
func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        skill.in_queue(char_, config)
    var msg_ID = Msg.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

    trigger_func = func (_msg) -> void:
        skill.out_queue(char_)
    msg_ID = Msg.listen_status_unsatisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

    # 判断当前状态是否满足。
    var result = Msg._resolve_target(char_, dependence_status)
    var char_listening: Character = result[0]
    var status_listening: String = result[1]
    if char_listening.statuses.check_satisfied(status_listening):
        skill.in_queue.call_deferred(char_, config)
    else:
        skill.out_queue.call_deferred(char_)

## 退订该角色的触发函数。被谁用：Skills.remove_skill。
func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
