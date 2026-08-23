class_name ShaderManager
extends RefCounted

# 文件名(不含扩展名) -> Shader
static var _shaders: Dictionary = {}

func _init() -> void:
    _load_shaders()


# 确保已扫描并加载所有 shader 文件
static func _load_shaders() -> void:
    if not _shaders.is_empty():
        return
    var dir := DirAccess.open(SysCfg.SHADERS_DIR)
    if dir == null:
        push_error("无法打开 shader 目录: " + SysCfg.SHADERS_DIR)
        return
    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
        if file.ends_with(".gdshader") and not dir.current_is_dir():
            var name := file.get_basename()  # 文件名，不含扩展名
            _shaders[name] = load(SysCfg.SHADERS_DIR + "/" + file)
        file = dir.get_next()
    dir.list_dir_end()


# 按文件名访问 shader（不含扩展名），如 get_shader("p3d_mask")
static func get_shader(name: String) -> Shader:
    _load_shaders()
    return _shaders.get(name)


static func has_shader(name: String) -> bool:
    _load_shaders()
    return _shaders.has(name)
