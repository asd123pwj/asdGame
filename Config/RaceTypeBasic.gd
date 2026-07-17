class_name RaceTypeBasic
extends ConfigBase

"""
name: String, 
types: Array[String]=[], 
buffs: Array[String]=[], 
statuses: Array[String]=[]
"""

var values: Array[Array] = [
    [
        "Human",
        ["Attack", "Defense", "Health",],
        [],
        ["Live", "Injured"]
    ],
    [
        "Rabbit",
        ["Attack", "Defense", "Health",],
        ["Base Attack -1", "Base Defense -1",],
        ["Live", "Injured"]
    ],
]