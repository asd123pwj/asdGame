class_name  AttributeSetBasic 
extends ConfigBase


## name_index = [0]时 value[0][0]为value[0]名称
## name_index = [0, 1]时 "value[0][0] | value[0][1]"为value[0]名称
var name_index = [0] 
var values: Array[Array] = [
    [
        "Human A",
        ["Attack", "Defense", "Health",],
        []
    ],
    [
        "Human B",
        ["Attack", "Defense", "Health",],
        ["Base Attack +3"]
    ],
]
