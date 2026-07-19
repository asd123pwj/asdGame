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
        ["Attack", "Defense", "Health",],
        [],
        ["Live", "Injured", "Dead"]
    ],
    [
        "Rabbit",
        ["Attack", "Defense", "Health",],
        ["Base Attack -1", "Base Defense -1",],
        ["Live", "Injured", "Dead"],
        ["DropOnDeath"]
    ],
    [
        "Meat",
        ["Attack", "Defense", "Health",],
        ["Base Attack -1", "Base Defense -1",],
        ["Live", "Injured", "Dead"]
    ],
    [
        "Fur",
        ["Attack", "Defense", "Health",],
        ["Base Attack -1", "Base Defense -1",],
        ["Live", "Injured", "Dead"]
    ],
]