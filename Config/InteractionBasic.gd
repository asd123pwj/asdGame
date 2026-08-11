class_name  InteractionBasic 
extends ConfigBase

"""
name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Attack", "Detect=>Touch", ["Strength", "Defense", "Health"]],
    ["Eat", "Detect=>Edible"],
    ["Heal", "Detect=>Healable"],
]
