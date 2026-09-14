class_name ShaderManager
extends BaseClass
## shader 管理器：启动时把 shader 目录下的 .gdshader 全部加载进内存，按"文件名（不含扩展名）"取用。
## 被谁用：需要特效/遮罩材质的地方（如地图层的 p3d 遮罩），统一从 `Sys.shaders.get_shader(...)` 拿。

# 文件名(不含扩展名) -> Shader
static var _shaders: Dictionary = {}

## 起手就把 shader 目录扫一遍（懒加载也留着，见 _load_shaders 的重复调用保护）。
## 被谁用：Sys.init_sub_system。
func _init() -> void:
    _load_shaders()


# 确保已扫描并加载所有 shader 文件
## 扫 SysCfg.SHADERS_DIR，把每个 .gdshader 按文件名存进 _shaders；已加载过就直接返回。
## 被谁用：_init、get_shader、has_shader。
static func _load_shaders() -> void:
    if not _shaders.is_empty():
        return
    var dir := DirAccess.open(Sys.sysCfg.SHADERS_DIR)
    if dir == null:
        push_error("无法打开 shader 目录: " + Sys.sysCfg.SHADERS_DIR)
        return
    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
        if file.ends_with(".gdshader") and not dir.current_is_dir():
            var name := file.get_basename()  # 文件名，不含扩展名
            _shaders[name] = load(Sys.sysCfg.SHADERS_DIR + "/" + file)
        file = dir.get_next()
    dir.list_dir_end()


# 按文件名访问 shader（不含扩展名），如 get_shader("p3d_mask")
## 取 shader（没有返回 null）。
## 被谁用：需要材质的各处。
static func get_shader(name: String) -> Shader:
    _load_shaders()
    return _shaders.get(name)


## 有没有这个 shader（用前判断，避免直接吃 null）。
## 被谁用：需要按名字判断存在性的各处。
static func has_shader(name: String) -> bool:
    _load_shaders()
    return _shaders.has(name)
