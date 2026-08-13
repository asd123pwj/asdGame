class_name InventoryPreset
extends PresetRegister


""" ---------- Config ---------- """
var name: String
var inventory_name: String
var config: Array
var inventory: InventoryBase

""" ---------- Global ---------- """
static var _we: Dictionary[String, InventoryPreset] = {}

func _init(name: String, inventory_name: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.inventory_name = inventory_name
    self.config = config
    _get_inventory_by_name()

static func get_(name: String) -> InventoryPreset:
    return _we[name]


func _get_inventory_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == inventory_name:
            @warning_ignore("unsafe_method_access")
            inventory = load(cls["path"]).new()
            return
    push_error("找不到类: ", inventory_name)
    inventory = null


func listen(char_: Character) -> void:
    inventory.add_to_char(char_, config)