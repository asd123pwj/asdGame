class_name Archetype_Heal
extends ConfigBase


var values: Array[Dictionary] = [
    
    {
        "name": "Rebirth",
        "statuses": ["Rebirth"],
        "interactions": ["Rebirth"],
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

