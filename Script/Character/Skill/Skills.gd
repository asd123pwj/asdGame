class_name Skills
extends BaseClass
## 某角色的技能集合：已装技能 + "正在生效的技能队列"（逐帧执行）。
## 被谁用：Character.skills；Character.physics_process 驱动队列。

## 所属角色。被谁用：physics_process/act、add/remove。
var me: Character
## 已装技能：预设名 -> 预设。被谁用：check_skill、remove。
var skills: Dictionary[String, SkillPreset] = {}

## {act_func: config}
## 正在生效的技能队列（由 SkillPreset 的状态判定进出，逐帧 act）。
## 被谁用：physics_process、SkillBase.in_queue/out_queue。
var skill_queue: Dictionary[SkillBase, Array] = {}

## 动作流水（加装 / 移除 / **执行**）：键是**预设名**，实现见 `ActionHistory`（交互那边共用同一份）。
## "执行"那一笔由 `SkillBase.act` 记；技能每物理帧都在执行 ⇒ 由 `ActionHistory` 按
## "n 秒内超过 m 次就每秒只记第一次"限流（参数在 `SysCfg.history_window` / `history_window_max`）。
## **为什么要记**：不看流水只能看到"现在在不在跑"，看不到"最后一次跑是什么时候"。
## 被谁用：add_skill / remove_skill（自己记）、SkillBase.act（记 act）、UI_Skill（读它显示）。
var history: ActionHistory = ActionHistory.new()

## 装配：记下所属角色并装入原型声明的技能。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, skill_name: Array[String]) -> void:
    self.me = me
    add_skills(skill_name)

## 物理帧：没有身体就直接返回；否则依次执行队列里的技能，最后统一 move_and_slide。
## 被谁用：Character.physics_process。
func physics_process(delta: float) -> void:
    if me.body == null: 
        return
    for skill in skill_queue:
        skill.act(me, delta, skill_queue[skill])
    me.body.move_and_slide()

    


""" ---------- init ---------- """
## 批量加。被谁用：_init、运行时批量加。
func add_skills(skill_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in skill_name:
        codes.append(add_skill(name))
    return codes

## 加一个技能：登记 → 让预设开始监听依赖状态 → 广播。重复加返回 NOT_MODIFIED。
## 被谁用：add_skills、指令。
func add_skill(skill_name: String) -> Enums.Code:
    if skill_name in skills:
        return Enums.Code.NOT_MODIFIED
    var skill = SkillPreset.get_(skill_name)
    skills[skill_name] = skill
    skill.listen(me)
    history.record(skill_name, "add")
    Msg.send_skill_add(me, skill_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除。
func remove_skills(skill_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in skill_name:
        codes.append(remove_skill(name))
    return codes

## 移除一个技能：退订监听 → 从字典删 → 广播。
## 被谁用：remove_skills、指令。
func remove_skill(skill_name: String) -> Enums.Code:
    if not skill_name in skills:
        return Enums.Code.NOT_MODIFIED
    skills[skill_name].unlisten(me)
    skills.erase(skill_name)
    # 增 / 删是**结构变化**：流水照记，广播也照发（限流只挡"高频"那类，见 ActionHistory）
    history.record(skill_name, "remove")
    Msg.send_skill_remove(me, skill_name)
    return Enums.Code.OK

## 有没有装某个技能。被谁用：条件判定/指令。
func check_skill(skill_name: String) -> bool:
    return skills.has(skill_name)
