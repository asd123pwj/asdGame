class_name  SkillPreset_Basic 
extends ConfigBase

"""
name: String
skill_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Walk Right", "Skill_Walk", "Right@SYS", [300]],
    ["Walk Left", "Skill_Walk", "Left@SYS", [-300]],
    ["Free Fall", "Skill_Gravity", "AlwaysSatisfied@SYS"],
    ["Jump", "Skill_Jump", "Up@SYS", [500]],
    ["Air Drag", "Skill_Damping", "AlwaysSatisfied@SYS", [false, Vector2(0.5, 0.5)]],
    ["Ground Friction", "Skill_Damping", "AlwaysSatisfied@SYS", [true, Vector2(100, 100)]],
]
