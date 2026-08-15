class_name Archetype_Basic
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
        "name": "通用活体",
        "buffs": ["人被杀就会死"],
        "statuses": ["Dead", "Live", "Injured", "Detect=>Practice", "Health<=Base/2"],
        "interactions": ["Practice"],
        "behaviors": ["SayInjured", "TryHealSelf"],
        "packages": ["CanBeHealed"]
    },
    
]

