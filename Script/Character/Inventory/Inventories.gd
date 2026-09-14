class_name Inventories
extends BaseClass
## 某角色的背包集合：按"类型名"（如 Backpack / DeadDrop）存放存储实例。
## 注意键是**类型名**而非预设名：不同预设可以共用同一个类型名，也就是共用同一个存储空间。
## 被谁用：Character.inventories（角色装配时建）；交互（吃/掉/搜寻）与指令。

## 所属角色。被谁用：各读写方法（存储实例按角色区分内容）。
var me: Character
## 这里的是类型名，而非配置名，以方便不同配置使用同一个类型的存储空间
## 被谁用：get_contents/print_contents、add/remove。
var inventories: Dictionary[String, InventoryBase] = {}
## 预设名 -> 预设参数（当前未使用，占位）。
static var presets: Dictionary[String, Array]

## 装配：记下所属角色并装入原型声明的背包。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, inventories_name: Array[String]) -> void:
    self.me = me
    add_inventories(inventories_name)

## 便捷取某类型的内容（见 get_contents）。
func get_DeadDrop() -> Array: return get_contents("DeadDrop")
## 便捷取某类型的内容（见 get_contents）。
func get_Backpack() -> Array: return get_contents("Backpack")
## 取某类型背包的内容（没有该类型返回空数组）。
## 被谁用：交互（Eat/Scan）、指令、UI 展示。
func get_contents(inventory_name: String) -> Array:
    if not inventories.has(inventory_name):
        return []
    return inventories[inventory_name].get_contents(me)

## 打印某类型背包的内容（调试用）。
## 被谁用：调试（如 Test 里 char_B.inventories.print_contents("DeadDrop")）。
func print_contents(inventory: String) -> void:
    if not inventories.has(inventory):
        return
    inventories[inventory].print_contents(me)



""" ---------- Init ---------- """
## 批量加。被谁用：_init、运行时批量加。
func add_inventories(inventories_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in inventories_name:
        codes.append(add_inventory(name))
    return codes

## 加一个背包：按预设取到"存储实例"并按类型名登记，然后让预设给本角色做初始化。
## 被谁用：add_inventories、指令。
func add_inventory(inventory_name: String) -> Enums.Code:
    if inventory_name in inventories:
        return Enums.Code.NOT_MODIFIED
    var inventory_preset = InventoryPreset.get_(inventory_name)
    # 这里的是类型名，而非配置名，以方便不同配置使用同一个类型的存储空间
    inventories[inventory_preset.inventory_name] = inventory_preset.inventory 
    inventory_preset.listen(me)
    Msg.send_inventory_add(me, inventory_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除。
func remove_inventories(inventories_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in inventories_name:
        codes.append(remove_inventory(name))
    return codes

## 移除一个背包（只是从字典里摘 + 广播，内容仍在存储实例里）。
## 被谁用：remove_inventories、指令。
func remove_inventory(inventory_name: String) -> Enums.Code:
    if not inventory_name in inventories:
        return Enums.Code.NOT_MODIFIED
    inventories.erase(inventory_name)
    Msg.send_inventory_remove(me, inventory_name)
    return Enums.Code.OK

## 有没有某个背包。被谁用：条件判定/指令。
func check_inventory(inventory_name: String) -> bool:
    return inventories.has(inventory_name)
