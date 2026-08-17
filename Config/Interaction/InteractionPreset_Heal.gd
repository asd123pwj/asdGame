class_name  InteractionPreset_Heal 
extends ConfigBase

"""
name: String
interaction_name: String
var dependence_status: String
var config: Array
"""
var values: Array[Array] = [
    ["Heal", "Interaction_Heal", "Detect=>Healable"],
    ["CostHeal", "Interaction_CostHeal", "Detect=>CostHeal"],
    ["Rebirth", "Interaction_Rebirth", "Dead"],
    ["TryHealSelf", "Interaction_TryHealSelf", "Health<=Base/2"],

]
