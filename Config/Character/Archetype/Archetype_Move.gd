class_name Archetype_Move
extends ConfigBase

var values: Array[Dictionary] = [
    {
        "name": "移动状态",
        "statuses": ["Right", "Up", "Left", "Down"],
        "skills": ["Walk Right", "Walk Left", "Free Fall", "Jump"],
    },
    {
        "name": "重力与阻力",
        "statuses": ["Tick"],
        "skills": ["Air Drag", "Ground Friction", "Free Fall"],
    }
]

