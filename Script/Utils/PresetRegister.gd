## 初始化时自动加载子类，子类为预设类
## 预设注册器：扫 Config/ 目录里"以本类的子类名开头"的脚本，把它们的 values 逐条实例化成预设。
## 被谁继承：UIPreset（extends PresetRegister，见 Script/UI/UIPreset.gd）。
class_name PresetRegister
extends BaseClass


# 可以简化，现在是每个类都扫描一遍，N个类N遍重复扫描
## 构造即扫描注册：找出所有"base 是本类"的全局类，逐个 register()。
## 被谁用：继承者的实例化（引擎在配置类/预设类 new 出来时自动走这里）。
func _init() -> void:
    var this_class: GDScript = PresetRegister as GDScript
    var parent_name: String = this_class.resource_path.get_file().get_basename()
    
    for cls in ProjectSettings.get_global_class_list():
        if cls["base"] == parent_name:
            var script: GDScript = load(cls["path"])
            register(script)
    

## 注册一个配置脚本：扫目录拿它的实例脚本 → 逐条生成预设。
## 被谁用：_init。
static func register(class_: GDScript) -> void:
    var scripts: Array[GDScript] = _scan(class_)
    _add_presets(class_, scripts)

## 递归扫描指定目录及其子目录下的所有 .gd 脚本
## 被谁用：register。
static func _scan(class_: GDScript) -> Array[GDScript]:
    var class_name_ = class_.resource_path.get_file().get_basename()
    var scripts : Array[GDScript] = []
    _scan_dir(Sys.SYS_CONFIG_DIR, class_name_, scripts)
    return scripts


## 扫描一个目录：跳过隐藏项，递归子目录，只收"文件名以 class_name_ 开头"的 .gd。
## 被谁用：_scan（递归）。
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

## 逐个实例化配置脚本（取它的 values），把每条 value 变成一个预设实例。
## 被谁用：register。
static func _add_presets(class_: GDScript, scripts: Array[GDScript]) -> void:
    for script: GDScript in scripts:
        var instance = script.new()
        for value in instance.values:
            _add_preset(class_, value)

## 造一条预设：数组 → callv(按位置传参)，字典 → call(单个字典参数)。
## 被谁用：_add_presets。
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
