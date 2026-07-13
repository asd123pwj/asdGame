class_name ConfigBase
extends RefCounted


func _init() -> void:
    var script: Script = get_script()
    var config_path = Sys.USER_CONFIG_DIR + script.get_global_name() + ".json"
    save_or_init(config_path)


func save_or_init(config_path: String) -> void:
    if (not FileAccess.file_exists(config_path)) or Sys.RESET:
        save(config_path)
        return

    var json = JSON.parse_string(FileAccess.get_file_as_string(config_path))
    if typeof(json) != TYPE_DICTIONARY:
        return

    for key in json:
        if key in self:
            _assign_property(key, json[key])


func _assign_property(name: String, value: Variant) -> void:
    var current : Variant = get(name)

    match typeof(current):

        TYPE_ARRAY:
            if value is Array:
                @warning_ignore("unsafe_method_access")
                current.clear()
                @warning_ignore("unsafe_method_access")
                current.append_array(value)

        TYPE_DICTIONARY:
            if value is Dictionary:
                @warning_ignore("unsafe_method_access")
                current.clear()
                @warning_ignore("unsafe_method_access")
                current.merge(value, true)

        TYPE_VECTOR2:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 2:
                current = Vector2(value[0], value[1])

        TYPE_VECTOR2I:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 2:
                current = Vector2i(value[0], value[1])

        TYPE_VECTOR3:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 3:
                current = Vector3(value[0], value[1], value[2])

        TYPE_VECTOR3I:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 3:
                current = Vector3i(value[0], value[1], value[2])

        TYPE_VECTOR4:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 4:
                current = Vector4(value[0], value[1], value[2], value[3])

        TYPE_VECTOR4I:
            @warning_ignore("unsafe_method_access")
            if value is Array and value.size() == 4:
                current = Vector4i(value[0], value[1], value[2], value[3])

        TYPE_COLOR:
            if value is String:
                current = Color.from_string(value, current)

        TYPE_NODE_PATH:
            if value is String:
                current = NodePath(value)

        _:
            current = value

    set(name, current)


func save(config_path: String) -> void:
    if not DirAccess.dir_exists_absolute(Sys.USER_CONFIG_DIR):
        DirAccess.make_dir_recursive_absolute(Sys.USER_CONFIG_DIR)

    var data := {}

    for prop in get_property_list():
        if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
            var name: String = prop.name
            if name.begins_with("_"):
                continue

            var value = get(name)

            match typeof(value):

                TYPE_COLOR:
                    @warning_ignore("unsafe_method_access")
                    data[name] = value.to_html()

                TYPE_VECTOR2:
                    data[name] = [value.x, value.y]

                TYPE_VECTOR2I:
                    data[name] = [value.x, value.y]

                TYPE_VECTOR3:
                    data[name] = [value.x, value.y, value.z]

                TYPE_VECTOR3I:
                    data[name] = [value.x, value.y, value.z]

                TYPE_VECTOR4:
                    data[name] = [value.x, value.y, value.z, value.w]

                TYPE_VECTOR4I:
                    data[name] = [value.x, value.y, value.z, value.w]

                TYPE_NODE_PATH:
                    data[name] = str(value)

                _:
                    data[name] = value

    var file := FileAccess.open(config_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()