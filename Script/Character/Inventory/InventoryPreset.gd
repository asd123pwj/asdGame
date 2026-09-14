class_name InventoryPreset
extends PresetRegister
## 背包预设：用哪个存储实现类（如 Backpack / DeadDrop）、初始内容是什么。
## 被谁用：Inventories.add_inventory（按名取）、Archetype 的 inventories 字段。

""" ---------- Config ---------- """
## 预设名（唯一）。被谁用：Inventories.add_inventory 与指令。
var name: String
## 存储实现类名（InventoryBase 子类）。被谁用：_get_inventory_by_name、Inventories 的字典键。
var inventory_name: String
## 传给实现类的初始化参数（如初始物品）。被谁用：listen。
var config: Array
## 存储实例（**每个预设一个**，多个角色共用同一个实例、内容按角色分）。被谁用：listen、Inventories。
var inventory: InventoryBase

""" ---------- Global ---------- """
## 全部预设：名 -> 实例。被谁用：InventoryPreset.get_。
static var _we: Dictionary[String, InventoryPreset] = {}

## 注册一条背包预设，并按类名实例化存储实现。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, inventory_name: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.inventory_name = inventory_name
    self.config = config
    _get_inventory_by_name()

## 按名取预设。被谁用：Inventories.add_inventory。
static func get_(name: String) -> InventoryPreset:
    return _we[name]


## 按类名从全局类表取实现类并 new 出存储实例（取不到报错）。
## 被谁用：_init。
func _get_inventory_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == inventory_name:
            @warning_ignore("unsafe_method_access")
            inventory = load(cls["path"]).new()
            return
    push_error("找不到类: ", inventory_name)
    inventory = null


## 让本背包对某角色生效（存储实例按角色记录内容）。
## 被谁用：Inventories.add_inventory。
func listen(char_: Character) -> void:
    inventory.add_to_char(char_, config)
