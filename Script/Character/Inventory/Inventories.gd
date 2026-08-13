class_name Inventories
extends PresetRegister


var me: Character
# 这里的是类型名，而非配置名，以方便不同配置使用同一个类型的存储空间
var inventories: Dictionary[String, InventoryBase] = {}
static var presets: Dictionary[String, Array]

func _init(me: Character, inventories_name: Array[String]) -> void:
    self.me = me
    add_inventories(inventories_name)

func get_DeadDrop() -> Array: return get_contents("DeadDrop")
func get_Backpack() -> Array: return get_contents("Backpack")
func get_contents(inventory_name: String) -> Array:
    if not inventories.has(inventory_name):
        return []
    return inventories[inventory_name].get_contents(me)

func print_contens(inventory: String) -> void:
    if not inventories.has(inventory):
        return
    inventories[inventory].print_contents(me)



""" ---------- Init ---------- """
func add_inventories(inventories_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in inventories_name:
        codes.append(add_inventory(name))
    return codes

func add_inventory(inventory_name: String) -> Enums.Code:
    if inventory_name in inventories:
        return Enums.Code.NOT_MODIFIED
    var inventory_preset = InventoryPreset.get_(inventory_name)
    # 这里的是类型名，而非配置名，以方便不同配置使用同一个类型的存储空间
    inventories[inventory_preset.inventory_name] = inventory_preset.inventory 
    inventory_preset.listen(me)
    MsgHubChar.send_inventory_add(me, inventory_name)
    return Enums.Code.OK

func remove_inventories(inventories_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in inventories_name:
        codes.append(remove_inventory(name))
    return codes

func remove_inventory(inventory_name: String) -> Enums.Code:
    if not inventory_name in inventories:
        return Enums.Code.NOT_MODIFIED
    inventories.erase(inventory_name)
    MsgHubChar.send_inventory_remove(me, inventory_name)
    return Enums.Code.OK

func check_inventory(inventory_name: String) -> bool:
    return inventories.has(inventory_name)
