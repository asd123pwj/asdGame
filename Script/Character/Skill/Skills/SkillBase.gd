class_name SkillBase
extends BaseClass
## 技能实现基类：子类只覆写 `_act()`（每物理帧做什么），进出队列与广播由本类统一处理。
## 队列是"按角色"的（char.skills.skill_queue），所以同一个技能实例能被多个角色共用。
## 被谁用：SkillPreset._get_skill_by_name（按类名 new 一份，全预设共用）。

## 自己的类名（子类名）。被谁用：广播 skill_act 时标识是哪个技能。
@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()


func _init() -> void:
    pass

## 进入执行队列（依赖状态"满足"时被调）。
## 被谁用：SkillPreset.listen 的触发函数。
func in_queue(_char: Character, _config: Array) -> void:
    _char.skills.skill_queue[self] = _config

## 移出执行队列（依赖状态"不满足"时被调）。
## 被谁用：SkillPreset.listen 的触发函数、Skills.remove_skill。
func out_queue(_char: Character) -> void:
    _char.skills.skill_queue.erase(self)

## 每帧执行：真正干活在 _act（子类覆写），成功则广播一次 skill_act。
## 被谁用：Skills.physics_process。
func act(_char: Character, _delta: float, _config: Array) -> bool:
    if _act(_char, _delta, _config):
        Msg.send_skill_act(_char, CLASS_NAME)
        return true
    return false

## 虚接口：子类覆写"本帧要对身体做什么"（返回是否算执行了）。
## 被谁用：act。实现者：Skill_Walk / Skill_Jump / Skill_Gravity / Skill_Damping。
func _act(_char: Character, _delta: float, _config: Array) -> bool:
    return true
