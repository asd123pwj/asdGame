class_name  InteractionBasic 
extends ConfigBase

"""
name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Attack", "Attack", "Detect=>Touch", ["Strength", "Defense", "Health"]],
    ["Eat", "Eat", "Detect=>Edible"],
    ["Heal", "Heal", "Detect=>Healable"],
    ["CostHeal", "CostHeal", "Detect=>CostHeal"],
    ["熟能生巧", "熟能生巧", "Detect=>熟能生巧"],
]
