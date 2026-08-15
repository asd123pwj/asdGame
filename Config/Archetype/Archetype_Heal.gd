class_name Archetype_Heal
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
        "name": "Rebirth",
        "statuses": ["Rebirth"],
        "behaviors": ["Rebirth"],
    },
    {
        "name": "CanBeHealed",
        "statuses": ["Detect=>CostHeal"],
        "interactions": ["CostHeal"],
    },
    {
        "name": "Healable",
        "statuses": ["Detect=>Healable", "Healable"],
        "interactions": ["Heal"],
    },
]

