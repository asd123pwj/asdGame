class_name Utils
extends RefCounted


static func find_dict(dict: Dictionary, keys: Array, default: Variant = {}):
    var current = dict
    for key in keys:
        if not current.has(key):
            return default
        current = current[key]
    return current


static func set_dict(dict: Dictionary, keys: Array, value: Variant) -> void:
    var current: Dictionary = dict
    for i in range(keys.size() - 1):  # 只到倒数第二个
        var key = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    current[keys[-1]] = value