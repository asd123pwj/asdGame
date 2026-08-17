class_name  InteractionPreset_Grow
extends ConfigBase

"""
name: String
interaction_name: String
var dependence_status: String
var config
"""
var values: Array[Array] = [
    ["Grow when hour advance", "Interaction_Practice", "Hour Advance", "Health"],
    ["Practice", "Interaction_Practice", "Detect=>Practice"],
    ["Nourish", "Interaction_AddBuff", "Detect=>Nourish", "Nourish"],
]
