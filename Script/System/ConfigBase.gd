class_name ConfigBase
extends RefCounted


const CONFIG_DIR := "user://Config/"
var _config_path: String = ""

func _init() -> void:
    _config_path = CONFIG_DIR + get_script().get_global_name() + ".json"
    save_or_init()

func save_or_init() -> void:
    if not FileAccess.file_exists(_config_path):
        save()
        return
    
    var json = JSON.parse_string(FileAccess.get_file_as_string(_config_path))
    if typeof(json) != TYPE_DICTIONARY:
        return
    
    for key in json:
        if key in self:   
            set(key, json[key])

func save() -> void:
    if not DirAccess.dir_exists_absolute(CONFIG_DIR):
        DirAccess.make_dir_recursive_absolute(CONFIG_DIR)

    var data := {}
    for prop in get_property_list():
        if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
            var name = prop.name
            if not name.begins_with("_"):   
                data[name] = get(name)
    
    var file = FileAccess.open(_config_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
