class_name BuffPreset_Grow
extends ConfigBase

"""
name: String,
category: String,
value_type: Enums.ValueType,
value: int | String
    为String时，取char_.attrs.get_(value)的值，value需属于任一category
method: Enums.ModificationMethod = Enums.ModificationMethod.ADD
    ADD, SUBTRACT, MULTIPLY, DIVIDE, SET
max_uses: int = -1
    -1表示无限使用次数
"""
var values: Array[Array] = [
    ["Nourish", "Health", Enums.ValueType.BASE, 20, Enums.ModificationMethod.ADD, 3]
]
