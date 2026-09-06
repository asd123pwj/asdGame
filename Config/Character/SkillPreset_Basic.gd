class_name  SkillPreset_Basic 
extends ConfigBase

"""
name: String
skill_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["WalkRight", "Skill_Walk", "Right", [300]],
    ["WalkLeft", "Skill_Walk", "Left", [-300]],
    ["FreeFall", "Skill_Gravity", "Tick"],
]
