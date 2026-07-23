class_name RaceTypeBasic
extends ConfigBase

"""
name: String, 
types: Array[String]=[], 
buffs: Array[String]=[], 
statuses: Array[String]=[]
behaviors: Array[String]=[]
"""

var values: Array[Array] = [
    [
        "Human",
        ["Strength", "Defense", "Health",],
        [],
        ["Live", "Injured", "Dead", "Rebirth", "Touch"],
        [],
        ["Attack"]
    ],
    [
        "Rabbit",
        ["Strength", "Defense", "Health",],
        ["Base Strength -1", "Base Defense -1",],
        ["Live", "Injured", "Dead", "Rebirth", "Touch"],
        ["DropOnDeath", "Rebirth"],
        ["Attack"]
    ],
    [
        "Meat",
        ["Strength", "Defense", "Health",],
        ["Base Strength -1", "Base Defense -1",],
        ["Live", "Injured", "Dead"]
    ],
    [
        "Fur",
        ["Strength", "Defense", "Health",],
        ["Base Strength -1", "Base Defense -1",],
        ["Live", "Injured", "Dead"]
    ],
]