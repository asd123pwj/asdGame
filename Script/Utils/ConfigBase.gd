class_name ConfigBase
extends BaseClass
## 配置基类（见 Script/设计文档.md）：**每个配置类 = 一组可被 json 覆盖的变量**。
## 子类（Config/ 下那些 `extends ConfigBase`，如 UIPreset_Basic / UIPreset_Menu）把配置写成
## `var values: Array[Array]` 之类的脚本变量；本类负责：
##   启动时按"脚本全局类名.json"决定"读盘覆盖 values"还是"把 values 写盘"（Sys.RESET 控制）。
## 注意：json 的 key 只能是字符串，所以配置里别用数组/字典当 key（会被 String() 掉）。

## 构造即加载：立刻按脚本名去 USER_CONFIG_DIR 找 json（找不到或 Sys.RESET 就写盘生成）。
## 被谁用：所有配置类的实例化（PresetRegister._add_presets 里 script.new()）。
func _init() -> void:
    var script: Script = get_script()
    var config_path = Sys.USER_CONFIG_DIR + script.get_global_name() + ".json"
    save_or_init(config_path)


## 读盘覆盖变量，或首次/RESET 时写盘。json 顶层不是字典就静默返回（保持代码里的默认值）。
## 被谁用：_init。
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


## 把 json 里的值赋给同名变量，按"变量当前类型"做还原：
## Array/Dictionary 就地 clear+合并（保持引用不变），各 Vector/Color/NodePath 由数组或字符串还原。
## 被谁用：save_or_init。
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


## 把本类的脚本变量写盘（跳过 `_` 开头的私有变量），Vector/Color/NodePath 转成数组或字符串。
## 被谁用：save_or_init（首次/RESET 时）；想手动存盘也调它。
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
