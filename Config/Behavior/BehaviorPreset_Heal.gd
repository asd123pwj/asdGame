class_name  BehaviorPreset_Heal 
extends ConfigBase

"""
name: String
behavior_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Rebirth", "Behavior_Rebirth", "Dead"],
    ["TryHealSelf", "Behavior_TryHealSelf", "Health<=Base/2"],
]
