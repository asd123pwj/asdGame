class_name StatusPreset_Heal
extends ConfigBase

var values: Array[Dictionary] = [
    {
        "name": "Health<=Base/2",
        "attrs": [["Health", "<=Base/", 2]]
    },
    {
        "name": "Healable" # 仅name时默认为true，可以作为标识符，用satisfied检测标识
    },
    {
        "name": "Detect=>Healable",
        "auto_reset": true,
        "with_detect": true,
    },
    {   
        "name": "Detect=>CostHeal",
        "auto_reset": true,
        "with_detect": true,
    },
    {
        "name": "Rebirth",
        "auto_reset": true,
        "interactions": [["Rebirth", "Act"]],
    }, 
]
