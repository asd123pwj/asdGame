# ## 此类用于自动搜索预设配置，及加载预设
# ## 此类可不作为基类，但为了标识方便，它应该作为基类
# ## 它需要子类有方法变量static var new_: Callable
# ## 预设配置说明：有类xxx，其在res//:Config/xxx/下有若干配置文件，如xxxBasic.gd
# ## 配置文件有属性name_index，为预设名格式化方法，
# ## 有变量values，为预设的初始化参数
# class_name PresetRegister
# extends RefCounted


# ## {Class, {preset_name, preset_args}}
# static var _presets: Dictionary[GDScript, Dictionary] = {}


# ## 给定类class_，自动扫描"res://Config/class_"下的配置文件，并以此实例化class_
# ## 
# ## 说明
# ## 
# ## 有类class_，class_有一系列配置文件在"res://Config/class_"里作为.gd文件
# ##     例如"res://Config/class_/_classBasic.gd"
# ## 而_classBasic.gd有属性value，value是一个数组，数组里是class_的各配置的参数
# ## 使用各配置的参数可以实例化class_
# ## 而实例化class_会自动注册该实例
# ## 
# ## 举例来说，有类AttributeBuff，
# ##     AttributeBuff的初始化参数为name: String, type_name: String, buff_value: int, impact_type: Enums.ValueType
# ## 在"res://Config/AttributeBuff/"下有若干配置文件，如AttributeBuffBasic.gd
# ##     AttributeBuffBasic有属性value，例如
# ##         var value: Array[Array] = [
# ##             ["Base Attack +1", "Attack", 1, Enums.ValueType.BASE],
# ##             ["Base Attack +2", "Attack", 2, Enums.ValueType.BASE],
# ##         ]
# ## 随后，使用value里的参数实例化AttributeBuff
# static func register(class_: GDScript) -> void:
#     var config_dir = Sys.SYS_CONFIG_DIR + class_.resource_path.get_file().get_basename()
#     var scripts: Array[GDScript] = _scan(config_dir)
#     _presets[class_] = {}
#     _add_new(class_)
#     _add_presets(class_, scripts)

# ## 扫描指定目录下的所有 .gd 脚本
# static func _scan(config_dir: String) -> Array[GDScript]:
#     var scripts : Array[GDScript] = []
#     var dir = DirAccess.open(config_dir)
#     if not dir:
#         push_warning("ConfigScanner: 目录不存在: ", config_dir)
#         return scripts
#     dir.list_dir_begin()
#     var file_name = dir.get_next()
#     while file_name != "":
#         if file_name.ends_with(".gd") and not file_name.begins_with("."):
#             var script_path = config_dir.path_join(file_name)
#             var script : GDScript = load(script_path)
#             if script and script is GDScript and script.can_instantiate():
#                 scripts.append(script)
#         file_name = dir.get_next()
#     dir.list_dir_end()
#     return scripts

# static func _add_presets(class_: GDScript, scripts: Array[GDScript]) -> void:
#     for script: GDScript in scripts:
#         var instance = script.new()
#         var name_formatter: Callable = _make_formatter(instance.name_index)
#         for value in instance.values:
#             # naming
#             var name: String = name_formatter.call(value)
#             # add
#             _add_preset(class_, name, value)

# static func _make_formatter(indices: Array) -> Callable:
#     return func(values: Array) -> String:
#         var parts = []
#         for idx in indices:
#             if idx < 0 or idx >= values.size():
#                 push_error("索引 %d 超出列表范围（大小 %d）" % [idx, values.size()])
#                 return ""
#             parts.append(str(values[idx]))
#         return "|".join(parts)

# static func _add_preset(class_: GDScript, name: String, args: Array) -> void:
#     _presets[class_][name] = args

# static func _add_new(class_: GDScript):
#     var new_ = func new_(names: Array):
#         var name = "|".join(names)
#         var args = _presets[class_][name]
#         return class_.new.callv(args)
#     @warning_ignore("unsafe_property_access")
#     class_.new_ = new_
