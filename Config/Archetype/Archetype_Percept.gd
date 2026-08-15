class_name Archetype_Percept
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
        "name": "触觉",
        "statuses": ["Detect=>Touch"],
    },
    {
        "name": "掉落物感知",
        "collisions": ["掉落物检测"],
    },
]

