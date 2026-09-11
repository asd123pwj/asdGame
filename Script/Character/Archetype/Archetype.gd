class_name Archetype
extends PresetRegister


""" ---------- individual ---------- """
""" ----- Config ----- """
var name: String
var buffs: Array[String]
var statuses: Array[String]
# var behaviors: Array[String]
var interactions: Array[String]
var bodies: Array[String]
var skills: Array[String]
var collisions: Array[String]
var inventories: Array[String]
var shortcuts: Array[String]
var packages: Array[String]
var _unpacked: bool = false

""" ----- Global ----- """
static var _we: Dictionary[String, Archetype] = {}
## 各字段对应的预设类（按 archetype 的键名判断用哪个类加载内联配置）
static var _field_class: Dictionary[String, GDScript] = {
    "buffs": BuffPreset,
    "statuses": StatusPreset,
    "interactions": InteractionPreset,
    "bodies": BodyPreset,
    "skills": SkillPreset,
    "collisions": CollisionPreset,
    "inventories": InventoryPreset,
    "shortcuts": SystemShortcutPreset,
    "packages": Archetype,
}

func _init(config: Dictionary) -> void:
    self.name = config["name"]
    _we[name] = self

    self.buffs.assign(_load_field(config, "buffs"))
    self.statuses.assign(_load_field(config, "statuses"))
    # self.behaviors.assign(_load_field(config, "behaviors"))
    self.interactions.assign(_load_field(config, "interactions"))
    self.bodies.assign(_load_field(config, "bodies"))
    self.skills.assign(_load_field(config, "skills"))
    self.collisions.assign(_load_field(config, "collisions"))
    self.inventories.assign(_load_field(config, "inventories"))
    self.shortcuts.assign(_load_field(config, "shortcuts"))
    self.packages.assign(_load_field(config, "packages"))

## 读取某字段，返回预设名数组。
## 元素为字符串 → 视为已存在的预设名，直接用；
## 元素为字典/列表 → 视为内联配置，按字段对应的类现场创建（重名则报错），再取其 name。
static func _load_field(config: Dictionary, field: String) -> Array[String]:
    var names: Array[String] = []
    for item in Utils.find_dict(config, [field], []):
        names.append(_load_item(config["name"], field, item))
    return names

static func _load_item(owner: String, field: String, item) -> String:
    if item is String:
        return item

    var class_: GDScript = _field_class[field]
    var item_name: String = item["name"] if typeof(item) == TYPE_DICTIONARY else item[0]

    @warning_ignore("unsafe_property_access", "unsafe_method_access")
    if class_._we.has(item_name):
        push_error("Archetype: %s 的 %s 中「%s」已存在" % [owner, field, item_name])
        return item_name

    if typeof(item) == TYPE_DICTIONARY:
        class_.new(item)
    else:
        class_.new.callv(item)
    return item_name

static func get_(name: String) -> Archetype:
    var archetype: Archetype = _we[name]
    if archetype._unpacked:
        return archetype
    archetype._unpacked = true
    if not archetype.packages.is_empty():
        for package in archetype.packages:
            var content = get_(package)
            archetype.buffs.append_array(content.buffs)
            archetype.statuses.append_array(content.statuses)
            # archetype.behaviors.append_array(content.behaviors)
            archetype.interactions.append_array(content.interactions)
            archetype.bodies.append_array(content.bodies)
            archetype.skills.append_array(content.skills)
            archetype.collisions.append_array(content.collisions)
            archetype.inventories.append_array(content.inventories)
            archetype.shortcuts.append_array(content.shortcuts)

        # 去重
        # buff 不用去重
        # archetype.buffs.assign(_deduplicate(archetype.buffs))
        archetype.statuses.assign(_deduplicate(archetype.statuses))
        # archetype.behaviors.assign(_deduplicate(archetype.behaviors))
        archetype.interactions.assign(_deduplicate(archetype.interactions))
        archetype.bodies.assign(_deduplicate(archetype.bodies))
        archetype.skills.assign(_deduplicate(archetype.skills))
        archetype.collisions.assign(_deduplicate(archetype.collisions))
        archetype.inventories.assign(_deduplicate(archetype.inventories))
        archetype.shortcuts.assign(_deduplicate(archetype.shortcuts))

    return archetype


static func _deduplicate(arr: Array) -> Array:
    var result: Dictionary = {}
    for item in arr:
        result[item] = true  
    return result.keys()

