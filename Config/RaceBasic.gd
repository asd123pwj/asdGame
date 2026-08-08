class_name RaceBasic
extends ConfigBase

"""
name: String, 
# types: Array[String]=[], 
buffs: Array[String]=[], 
statuses: Array[String]=[],
behaviors: Array[String]=[],
interactions: Array[String]=[],
bodies: Array[String]=[],
skills: Array[String]=[],
collisions: Array[String]=[],
"""

var values: Array[Dictionary] = [
    {
        "name": "Human",
        "buffs": ["Strength Base +3", "Defense Base +3", "Health Base +3", "人被杀就会死"],
        "statuses": ["Dead", "Live", "Injured", "Rebirth", "Touch", 
                     "Right", "Up", "Left", "On Left", "Shift + Left Click"],
        "behaviors": [],
        "interactions": ["Attack"],
        "bodies": ["Human"],
        "skills": ["WalkRight", "WalkLeft"],
        "collisions": ["掉落物检测"]
    },
    {
        "name": "Rabbit",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3", "人被杀就会死", "生命源于力量 Base", "力量源于生命 Base"],
        "statuses": ["Live", "Dead", "Injured", "Rebirth", "Touch"],
        "behaviors": ["DropOnDeath", "Rebirth"],
        "interactions": ["Attack"],
        "bodies": ["Yang"]
    },
    {
        "name": "Meat",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3", "人被杀就会死"],
        "statuses": ["Dead", "Live", "Injured"],
        "behaviors": [],
        "interactions": [],
        "bodies": ["Yang"]
    },
    {
        "name": "Fur",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3", "人被杀就会死"],
        "statuses": ["Dead", "Live", "Injured"],
        "behaviors": [],
        "interactions": [],
        "bodies": ["Yang"]
    },
]