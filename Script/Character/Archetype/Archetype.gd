class_name Archetype
extends PresetRegister
## 原型（种族/模板）：一个角色"由哪些预设组成"的清单（buffs/statuses/interactions/bodies/skills/collisions/inventories/shortcuts）。
## 清单里既可以写已存在的预设名，也可以直接内联配置（见 _load_item）。
## packages = 打包复用：把别的原型的清单合并进来（get_ 时展开）。
## 被谁用：Character._init_from_archetype（按名取原型）、CharSys.spawn。
## 注意：本文件也是 Script/设计文档.md 里"内联配置写法"的示范点。

""" ---------- individual ---------- """
""" ----- Config ----- """
## 原型名（唯一）。被谁用：Archetype.get_、Character.archetype_type。
var name: String
## 以下每个字段都是一串"预设名"，同名部件类会按它去装配角色该部件。
var buffs: Array[String]
var statuses: Array[String]
# var behaviors: Array[String]
var interactions: Array[String]
var bodies: Array[String]
var skills: Array[String]
var collisions: Array[String]
var inventories: Array[String]
var shortcuts: Array[String]
## 要合并进来的其它原型名（展开时机见 get_）。
var packages: Array[String]
## packages 是否已展开过（展开只做一次）。
var _unpacked: bool = false

""" ----- Global ----- """
## 全部原型：名 -> 实例。被谁用：Archetype.get_。
static var _we: Dictionary[String, Archetype] = {}
## 各字段对应的预设类（按 archetype 的键名判断用哪个类加载内联配置）
## 被谁用：_load_item。
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

## 注册一条原型（各字段再解析成"预设名数组"）。
## 被谁用：PresetRegister 的注册流程（config["name"] 必填）。
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
## 被谁用：_init。
static func _load_field(config: Dictionary, field: String) -> Array[String]:
    var names: Array[String] = []
    for item in Utils.find_dict(config, [field], []):
        names.append(_load_item(config["name"], field, item))
    return names

## 把字段里的一项解析成预设名：字符串直接用；内联配置现场实例化（已存在同名则报错）。
## 被谁用：_load_field。
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

## 取原型（第一次取时展开 packages：合并各包的各字段并去重）。
## 被谁用：Character._init_from_archetype、ensure_body。
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


## 数组去重（保序不保证，用字典键收集）。
## 被谁用：get_（合并 packages 后）。
static func _deduplicate(arr: Array) -> Array:
    var result: Dictionary = {}
    for item in arr:
        result[item] = true  
    return result.keys()
