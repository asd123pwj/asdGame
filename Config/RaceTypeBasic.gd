class_name RaceTypeBasic
extends ConfigBase

## name_index = [0]时 value[0][0]为value[0]名称
## name_index = [0, 1]时 "value[0][0] | value[0][1]"为value[0]名称
var name_index = [0] 
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