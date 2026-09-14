class_name Utils
extends BaseClass
## 通用小工具：按"键路径"（Array）读写嵌套字典。
## 路径例：[ "statuses", "Nourish", "time" ] → dict["statuses"]["Nourish"]["time"]。
## 被谁用：按路径存/取嵌套配置与状态的地方（如 StatusPreset / Attributes 的 keys 路径读写）。


## 沿 keys 逐层取；中间缺任何一层就返回 default（不报错、不建节点）。
## 被谁用：按路径读取"可能不存在"的嵌套值。
static func find_dict(dict: Dictionary, keys: Array, default: Variant = {}):
    var current = dict
    for key in keys:
        if not current.has(key):
            return default
        current = current[key]
    return current

## 沿 keys 逐层写；中间缺的层自动建成空字典，最后一层赋 value。
## 被谁用：按路径写入嵌套值（写入会创建缺失的中间层）。
static func set_dict(dict: Dictionary, keys: Array, value: Variant) -> void:
    var current: Dictionary = dict
    for i in range(keys.size() - 1):  # 只到倒数第二个
        var key = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    current[keys[-1]] = value

## 沿 keys 取，取不到就把 default_value 写进去再返回（"取不到就初始化"的惯用写法）。
## 被谁用：需要"读时顺带建默认值"的地方。
static func get_or_set_dict(dict: Dictionary, keys: Array, default_value: Variant = {}) -> Variant:
    var current: Dictionary = dict
    for i in range(keys.size() - 1):
        var key = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    var last_key = keys[-1]
    if not current.has(last_key):
        current[last_key] = default_value
    return current[last_key]
