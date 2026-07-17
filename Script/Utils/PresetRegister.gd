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

## 扫描指定目录下的所有 .gd 脚本
static func _scan(class_: GDScript) -> Array[GDScript]:
    var class_name_ = class_.resource_path.get_file().get_basename()
    var scripts : Array[GDScript] = []
    var dir = DirAccess.open(Sys.SYS_CONFIG_DIR)
    if not dir:
        push_warning("ConfigScanner: 目录不存在: ", Sys.SYS_CONFIG_DIR)
        return scripts
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if not file_name.begins_with(class_name_):
            file_name = dir.get_next()
            continue
        if file_name.ends_with(".gd") and not file_name.begins_with("."):
            var script_path = Sys.SYS_CONFIG_DIR.path_join(file_name)
            var script : GDScript = load(script_path)
            if script and script is GDScript and script.can_instantiate():
                scripts.append(script)
        file_name = dir.get_next()
    dir.list_dir_end()
    return scripts

static func _add_presets(class_: GDScript, scripts: Array[GDScript]) -> void:
    for script: GDScript in scripts:
        var instance = script.new()
        for value in instance.values:
            _add_preset(class_, value)

static func _add_preset(class_: GDScript, args: Array) -> void:
    class_.new.callv(args)