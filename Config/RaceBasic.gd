class_name RaceBasic
extends ConfigBase

"""
name: String, 
# types: Array[String]=[], 
buffs: Array[String]=[], 
statuses: Array[String]=[],
behaviors: Array[String]=[],
interactions: Array[String]=[]
"""

var values: Array[Array] = [
    [
        "Human",
        # ["Strength", "Defense", "Health",],
        ["Strength Base +3", "Defense Base +3", "Health Base +3", "人被杀就会死"],
        ["Dead", "Live", "Injured", "Rebirth", "Touch"],
        [],
        ["Attack"]
    ],
    [
        "Rabbit",
        # ["Strength", "Defense", "Health",],
        ["Strength Base +2", "Defense Base +2", "Health Base +3", 
         "人被杀就会死", "生命源于力量 Base", "力量源于生命 Base"],
        ["Live", "Dead", "Injured", "Rebirth", "Touch"],
        ["DropOnDeath", "Rebirth"],
        ["Attack"]
    ],
    [
        "Meat",
        # ["Strength", "Defense", "Health",],
        ["Strength Base +2", "Defense Base +2", "Health Base +3", "人被杀就会死"],
        ["Dead", "Live", "Injured", ]
    ],
    [
        "Fur",
        # ["Strength", "Defense", "Health",],
        ["Strength Base +2", "Defense Base +2", "Health Base +3", "人被杀就会死"],
        ["Dead", "Live", "Injured", ]
    ],
]