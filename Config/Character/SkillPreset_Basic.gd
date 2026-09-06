class_name  SkillPreset_Basic 
extends ConfigBase

"""
name: String
skill_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Walk Right", "Skill_Walk", "Right", [300]],
    ["Walk Left", "Skill_Walk", "Left", [-300]],
    ["Free Fall", "Skill_Gravity", "Tick"],
    ["Jump", "Skill_Jump", "Up", [500]],
    ["Air Drag", "Skill_Damping", "Tick", [false, Vector2(0.5, 0.5)]],
    ["Ground Friction", "Skill_Damping", "Tick", [true, Vector2(100, 100)]],
]
