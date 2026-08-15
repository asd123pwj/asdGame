class_name Archetype_Move
extends ConfigBase

"""
name: String, 
buffs: Array[String]=[], 
statuses: Array[String]=[],
behaviors: Array[String]=[],
interactions: Array[String]=[],
bodies: Array[String]=[],
skills: Array[String]=[],
collisions: Array[String]=[],
packages: Array[String]=[],
"""

var values: Array[Dictionary] = [
    {
        "name": "移动状态",
        "statuses": ["Right", "Up", "Left", "Down"],
        "skills": ["WalkRight", "WalkLeft"],
    },
]

