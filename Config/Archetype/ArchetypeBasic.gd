class_name ArchetypeBasic
extends ConfigBase

"""
name: String, 
buffs: Array[String]=[], 
statuses: Array[String]=[],
behaviors: Array[String]=[],
interactions: Array[String]=[],
bodies: Array[String]=[],
skills: Array[String]=[],
collisions: Array[String]=[],
packages: Array[String]=[],
"""

var values: Array[Dictionary] = [
    {
        "name": "通用活体",
        "buffs": ["人被杀就会死"],
        "statuses": ["Dead", "Live", "Injured"],
        "behaviors": ["SayInjured"],
        "packages": ["CanBeHealed"]
    },
    {
        "name": "移动状态",
        "statuses": ["Right", "Up", "Left", "Down"],
        "skills": ["WalkRight", "WalkLeft"],
    },
    
    {
        "name": "重生",
        "statuses": ["Rebirth"],
        "behaviors": ["Rebirth"],
    },
    {
        "name": "死亡掉落",
        "behaviors": ["DropOnDeath"],
    },
    {
        "name": "触觉",
        "statuses": ["Detect=>Touch"],
    },
    {
        "name": "掉落物感知",
        "collisions": ["掉落物检测"],
    },
    {
        "name": "接触伤害",
        "interactions": ["Attack"],
    },
    {
        "name": "消化系统",
        "statuses": ["Detect=>Edible"],
        "interactions": ["Eat"],
    },
    {
        "name": "CanBeHealed",
        "statuses": ["Detect=>CostHeal"],
        "interactions": ["CostHeal"],
    },
    {
        "name": "Healable",
        "statuses": ["Detect=>Healable", "Healable"],
        "interactions": ["Heal"],
    }
]

