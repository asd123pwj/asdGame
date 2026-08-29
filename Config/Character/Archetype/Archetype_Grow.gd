class_name Archetype_Grow
extends ConfigBase


var values: Array[Dictionary] = [
    {
        "name": "Grow when hour advance",
        "interactions": ["Grow when hour advance"],
        "statuses": ["Hour Advance"]
    },
    {
        "name": "Practice",
        "statuses": ["Detect=>Practice"],
        "interactions": ["Practice"],
    },
    {
        "name": "Nourish",
        "statuses": ["Detect=>Nourish"],
        "interactions": ["Nourish"],
    }
]

