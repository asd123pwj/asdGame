class_name InventoryBase
extends RefCounted

@warning_ignore("unsafe_method_access")
var CLASS_NAME: String = get_script().get_global_name()

var contents: Dictionary[Character, Array] = {}


func get_contents(me) -> Array:
    return contents[me]

func print_contents(me) -> void:
    for item in contents[me]:
        print("Item: ", item.name)

func add_to_char(me: Character, config: Array) -> void:
    contents[me] = []
    put_contents(me, config)

func put_contents(me, characters_or_races) -> void:
    for character_or_race in characters_or_races:
        put_content(me, character_or_race)


func put_content(me, character_or_race) -> void:
    if character_or_race is Character:
        contents[me].append(character_or_race)
    elif character_or_race is String:
        var char_ = CharSys.spawn(character_or_race)
        contents[me].append(char_)
    else:
        print("Error: Invalid argument type for put_content()")
        