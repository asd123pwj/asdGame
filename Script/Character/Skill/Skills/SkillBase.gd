class_name SkillBase
extends BaseClass
## 技能实现基类：子类只覆写 `_act()`（每物理帧做什么），进出队列与广播由本类统一处理。
## 队列是"按角色"的（char.skills.skill_queue），所以同一个技能实例能被多个角色共用。
## 被谁用：SkillPreset._get_skill_by_name（按类名 new 一份，全预设共用）。

## 自己的类名（子类名）。被谁用：一览里显示"实现类"（广播 skill_act 用的是**预设名**，见 preset_name）。
@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()
## 所属预设名（`SkillPreset._get_skill_by_name` 建完就写进来）。被谁用：act（记流水 + 广播）、一览。
var preset_name: String = ""


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

## 每帧执行：真正干活在 _act（子类覆写），成功则**先记流水、再广播**一次 skill_act。
## **广播用的是预设名**（不是类名）：技能域里 add / remove / act 三个动作的"技能名"都指预设名
## （`Skills` 的字典键），这样一览那边按同一个名字就能对上。
## **消息照发、每帧都发**（限流只在流水那边，见 ActionHistory）——订阅方要自己扛住这个频率：
## 技能一览因此不重铺界面，只把标题那一行字换掉，而且"文本没变就不刷"（流水到秒 ⇒ 一秒最多画一次）。
## 消息本身的开销真成了问题再说，别拿"要不要发"当限流手段（那会把别的订阅方也一起坑了）。
## 被谁用：Skills.physics_process。
func act(_char: Character, _delta: float, _config: Array) -> bool:
    if _act(_char, _delta, _config):
        # 先记流水（订阅方——技能一览——要读到刚记下的这一笔才算得对"最后时间"）；
        # **记不上也照样广播**：限流只管流水，消息该发就发。
        _char.skills.history.record(preset_name, "act")
        Msg.send_skill_act(_char, preset_name)
        return true
    return false

## 虚接口：子类覆写"本帧要对身体做什么"（返回是否算执行了）。
## 被谁用：act。实现者：Skill_Walk / Skill_Jump / Skill_Gravity / Skill_Damping。
func _act(_char: Character, _delta: float, _config: Array) -> bool:
    return true
