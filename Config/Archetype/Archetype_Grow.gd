class_name Archetype_Grow
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
        "name": "Grow when hour advance",
        "behaviors": ["Grow when hour advance"],
        "statuses": ["Hour Advance"],
        "packages": ["成长基本状态"]
    },
    {
        "name": "成长基本状态",
        "statuses": ["Detect=>Grow"],
        "interactions": ["Grow"],
    },
    {
        "name": "Practice",
        "statuses": ["Detect=>Practice"],
        "interactions": ["Practice"],
    },
]

