class_name Utils
extends RefCounted


static func get_dict(dict: Dictionary, ...keys) -> Dictionary:
    var current: Dictionary = dict
    for key in keys:
        if not current.has(key):
            current[key] = {}
        var next: Dictionary = current[key]
        current = next
    return current

static func find_dict(dict: Dictionary, ...keys) -> Dictionary:
    var current: Dictionary = dict
    for key in keys:
        if not current.has(key):
            return {}
        current = current[key]
    return current