class_name Skills
extends RefCounted


var me: Character
var skills: Dictionary[String, SkillPreset] = {}

## {act_func: config}
var skill_queue: Dictionary[SkillBase, Array] = {}

func _init(me: Character, skill_name: Array[String]) -> void:
    self.me = me
    add_skills(skill_name)

func physics_process(delta: float) -> void:
    for skill in skill_queue:
        skill.act(me, delta, skill_queue[skill])
        
        


""" ---------- init ---------- """
func add_skills(skill_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in skill_name:
        codes.append(add_skill(name))
    return codes

func add_skill(skill_name: String) -> Enums.Code:
    if skill_name in skills:
        return Enums.Code.NOT_MODIFIED
    var skill = SkillPreset.get_(skill_name)
    skills[skill_name] = skill
    skill.listen(me)
    MsgHubChar.send_skill_add(me, skill_name)
    return Enums.Code.OK

func remove_skills(skill_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in skill_name:
        codes.append(remove_skill(name))
    return codes

func remove_skill(skill_name: String) -> Enums.Code:
    if not skill_name in skills:
        return Enums.Code.NOT_MODIFIED
    skills[skill_name].unlisten(me)
    skills.erase(skill_name)
    MsgHubChar.send_skill_remove(me, skill_name)
    return Enums.Code.OK

func check_skill(skill_name: String) -> bool:
    return skills.has(skill_name)
