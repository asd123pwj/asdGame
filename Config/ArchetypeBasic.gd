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
        "statuses": ["Touch"],
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
        "name": "Human",
        "buffs": ["Strength Base +3", "Defense Base +3", "Health Base +3"],
        "bodies": ["Human"],
        "packages": ["通用活体", "移动状态", "重生", "死亡掉落", "触觉", "掉落物感知", "接触伤害"]
    },
    {
        "name": "Rabbit",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3", "生命源于力量 Base", "力量源于生命 Base"],
        "bodies": ["Yang"],
        "packages": ["通用活体", "重生", "死亡掉落", "触觉", "掉落物感知", "接触伤害"]
    },
    {
        "name": "Meat",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3"],
        "bodies": ["Yang"],
    },
    {
        "name": "Fur",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3"],
        "bodies": ["Yang"],
    },
]

