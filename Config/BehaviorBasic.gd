class_name  BehaviorBasic 
extends ConfigBase

"""
name: String
behavior_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["DropOnDeath", "DropOnDeath", "Dead", ["Meat", "Fur"]],
    ["Rebirth", "Rebirth", "Dead"],
    ["SayInjured", "SayChanged", "Injured", ["Health"]]
]
