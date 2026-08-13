## 初始化时自动加载子类，子类为预设类
class_name PresetRegister
extends RefCounted


# 可以简化，现在是每个类都扫描一遍，N个类N遍重复扫描
func _init() -> void:
    var this_class: GDScript = PresetRegister as GDScript
    var parent_name: String = this_class.resource_path.get_file().get_basename()
    
    for cls in ProjectSettings.get_global_class_list():
        if cls["base"] == parent_name:
            var script: GDScript = load(cls["path"])
            register(script)
    

static func register(class_: GDScript) -> void:
    var scripts: Array[GDScript] = _scan(class_)
    _add_presets(class_, scripts)

## 递归扫描指定目录及其子目录下的所有 .gd 脚本
static func _scan(class_: GDScript) -> Array[GDScript]:
    var class_name_ = class_.resource_path.get_file().get_basename()
    var scripts : Array[GDScript] = []
    _scan_dir(Sys.SYS_CONFIG_DIR, class_name_, scripts)
    return scripts


static func _scan_dir(path: String, class_name_: String, scripts: Array[GDScript]) -> void:
    var dir = DirAccess.open(path)
    if not dir:
        push_warning("ConfigScanner: 目录不存在: ", path)
        return
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        var full_path = path.path_join(file_name)
        if file_name.begins_with("."):
            pass  # 跳过隐藏文件/目录
        elif dir.current_is_dir():
            _scan_dir(full_path, class_name_, scripts)  # 递归子目录
        elif file_name.begins_with(class_name_) and file_name.ends_with(".gd"):
            var script : GDScript = load(full_path)
            if script and script is GDScript and script.can_instantiate():
                scripts.append(script)
        file_name = dir.get_next()
    dir.list_dir_end()

static func _add_presets(class_: GDScript, scripts: Array[GDScript]) -> void:
    for script: GDScript in scripts:
        var instance = script.new()
        for value in instance.values:
            _add_preset(class_, value)

static func _add_preset(class_: GDScript, args) -> void:
    # if class_ is InventoryBase:
    #     class_.presets[args[0]] = args

    if typeof(args) == TYPE_ARRAY:
        class_.new.callv(args)
    elif typeof(args) == TYPE_DICTIONARY:
        class_.new.call(args)
    else:
        ## TODO: 报错
        print("ConfigScanner: 不支持的参数类型: ", typeof(args))
