class_name  AttributeBuffBasic 
extends ConfigBase

## name_index = [0]时 value[0][0]为value[0]名称
## name_index = [0, 1]时 "value[0][0] | value[0][1]"为value[0]名称
var name_index = [0] 
var values: Array[Array] = [
    ["Base Attack +1", "Attack", 1, Enums.ValueType.BASE],
    ["Base Attack +2", "Attack", 2, Enums.ValueType.BASE],
    ["Base Attack +3", "Attack", 3, Enums.ValueType.BASE],
    ["Base Attack -1", "Attack", -1, Enums.ValueType.BASE],
    ["Base Attack -2", "Attack", -2, Enums.ValueType.BASE],
    ["Base Attack -3", "Attack", -3, Enums.ValueType.BASE],
    
    ["Base Defense +1", "Defense", 1, Enums.ValueType.BASE],
    ["Base Defense +2", "Defense", 2, Enums.ValueType.BASE],
    ["Base Defense +3", "Defense", 3, Enums.ValueType.BASE],
    ["Base Defense -1", "Defense", -1, Enums.ValueType.BASE],
    ["Base Defense -2", "Defense", -2, Enums.ValueType.BASE],
    ["Base Defense -3", "Defense", -3, Enums.ValueType.BASE],

    ["Base Health +1", "Health", 1, Enums.ValueType.BASE],
    ["Base Health +2", "Health", 2, Enums.ValueType.BASE],
    ["Base Health +3", "Health", 3, Enums.ValueType.BASE],
    ["Base Health -1", "Health", -1, Enums.ValueType.BASE],
    ["Base Health -2", "Health", -2, Enums.ValueType.BASE],
    ["Base Health -3", "Health", -3, Enums.ValueType.BASE]
]
