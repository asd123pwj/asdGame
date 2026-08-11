class_name ArchetypeRace
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
        "name": "人类",
        "buffs": ["Strength Base +3", "Defense Base +3", "Health Base +3"],
        "bodies": ["Human"],
        "packages": ["通用活体", "移动状态", "重生", "死亡掉落", "触觉", "掉落物感知", "接触伤害"]
    },
    {
        "name": "兔子",
        "buffs": ["Strength Base +2", "Defense Base +2", "Health Base +3", "生命源于力量 Base", "力量源于生命 Base"],
        "bodies": ["Yang"],
        "packages": ["通用活体", "重生", "死亡掉落", "触觉", "掉落物感知", "接触伤害", "消化系统"]
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
    {
        "name": "草药",
        "buffs": ["Health Base +3",],
        "bodies": ["Yang"],
        "packages": ["通用活体", "Healable"]
    }
]

