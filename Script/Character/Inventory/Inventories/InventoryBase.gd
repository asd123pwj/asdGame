class_name InventoryBase
extends BaseClass
## 存储实现基类：**内容按角色分开存放**（同一个存储实例被多个角色共用，所以用 contents 分开）。
## 子类只是命名不同的存储空间（Backpack / DeadDrop），行为都由这里提供。
## 被谁用：InventoryPreset._get_inventory_by_name（按类名 new 一份，全预设共用）。

## 自己的类名（子类名）。被谁用：调试/日志区分是哪种存储。
@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()

## 每个角色的内容列表。被谁用：所有读写方法。
var contents: Dictionary[Character, Array] = {}


## 取某角色的内容列表。被谁用：Inventories.get_contents。
func get_contents(me) -> Array:
    return contents[me]

## 打印某角色的内容（调试用）。被谁用：Inventories.print_contents。
func print_contents(me) -> void:
    for item in contents[me]:
        print("Item: ", item.name)

## 给某角色初始化内容（先清空再放入 config 里的条目）。
## 被谁用：InventoryPreset.listen。
func add_to_char(me: Character, config: Array) -> void:
    contents[me] = []
    put_contents(me, config)

## 批量放入。被谁用：add_to_char、运行时塞东西。
func put_contents(me, characters_or_races) -> void:
    for character_or_race in characters_or_races:
        put_content(me, character_or_race)


## 放入一条：Character 直接收；字符串视为"种族/原型名"现场 spawn 一个。
## 被谁用：put_contents。
func put_content(me, character_or_race) -> void:
    if character_or_race is Character:
        contents[me].append(character_or_race)
    elif character_or_race is String:
        var char_ = CharSys.spawn(character_or_race)
        contents[me].append(char_)
    else:
        print("Error: Invalid argument type for put_content()")
    
