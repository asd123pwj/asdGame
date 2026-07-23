class_name  AttributeBuffBasic 
extends ConfigBase

"""
name: String, 
type_name: String, 
buff_value: int, 
impact_type: Enums.ValueType

"""
var values: Array[Array] = [
    ["Base Strength +1", "Strength", 1, Enums.ValueType.BASE],
    ["Base Strength +2", "Strength", 2, Enums.ValueType.BASE],
    ["Base Strength +3", "Strength", 3, Enums.ValueType.BASE],
    ["Base Strength -1", "Strength", -1, Enums.ValueType.BASE],
    ["Base Strength -2", "Strength", -2, Enums.ValueType.BASE],
    ["Base Strength -3", "Strength", -3, Enums.ValueType.BASE],
    
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
