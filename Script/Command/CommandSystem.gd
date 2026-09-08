## 继承BaseClass的类，其静态方法可以用"类名.方法名 参数"作为命令调用。
##     MapSys.place 0 5 -10 门 2 -1 true
##     MapSys.place --layer_id 0 --x 10 --source_name 门 --tile_name 2 --force_space
## 支持使用静态变量
##
class_name CmdSys
extends BaseClass


static var _commands: Dictionary = {}   # cmd_name -> { callable, arg_meta }


# 初始化（幂等）：注册命令 + 监听消息总线的 "COMMAND"。
# 由系统启动时 new 一次触发，例如 SystemManager.init_sub_system() 里 CmdSys.new()。
func _init() -> void:
	if not Sys.sysCfg.lazy_command_registration:
		_scan_all_sources()
	MsgHubCmd.listen_cmd(
		func(message: Variant) -> Variant:
			return execute(str(message))
	)


# 扫描所有最终继承 BaseClass 的类（含间接继承，如父类的父类是 BaseClass），
# 注册其非私有静态方法为命令。命令名 = "类名.方法名"（class_name 取自全局类表）。
static func _scan_all_sources() -> void:
	var entries := ProjectSettings.get_global_class_list()
	var by_name := {}
	for e in entries:
		by_name[e["class"]] = e
	for cls in entries:
		if cls["class"] == "CmdSys":      # 排除自身，避免自我注册
			continue
		if not _descends_from(cls, "BaseClass", by_name):
			continue
		var script: GDScript = load(cls["path"])
		if script == null:
			continue
		_register_source_methods(cls["class"], script)


# 判断某个全局类记录（entry）是否最终继承自 root_name（沿 base 链上溯）。
# get_global_class_list 的 "base" 只给直接父类名，需递归查祖先。
static func _descends_from(entry: Dictionary, root_name: String, by_name: Dictionary) -> bool:
	var cur: Dictionary = entry
	while cur.has("base") and cur["base"] != "":
		if cur["base"] == root_name:
			return true
		if not by_name.has(cur["base"]):
			break   # base 是未注册的类（如内置类）或链断了
		cur = by_name[cur["base"]]
	return false


# 把某个命令源脚本里非 "_" 开头的静态方法注册为命令。
# class_name_: 类名（命令名前缀）；script: 对应脚本。
static func _register_source_methods(class_name_: String, script: GDScript) -> void:
	for m_raw in script.get_script_method_list():
		var m: Dictionary = m_raw
		var method_name: String = m["name"]
		if method_name.begins_with("_"):
			continue
		# 只收 static（get_script_method_list 的 flags 含 METHOD_FLAG_STATIC）
		if m.get("flags", 0) & METHOD_FLAG_STATIC == 0:
			continue
		var cmd_name: String = class_name_ + "." + method_name
		_commands[cmd_name] = { "callable": Callable(script, method_name), "arg_meta": _make_arg_meta(m) }


# 从反射到的方法信息构造参数元信息数组。
# default_args 只含末尾若干有默认值的参数，按位对齐补到对应参数，
# 因此省略某参数时会自动用方法签名里写的默认值（如 variant=-1）。
static func _make_arg_meta(m: Dictionary) -> Array:
	var arg_list: Array = m["args"]
	var default_args: Array = m.get("default_args", [])
	var first_default: int = arg_list.size() - default_args.size()  # 第一个有默认值的参数下标
	var arg_meta: Array = []
	for i in arg_list.size():
		var a: Dictionary = arg_list[i]
		arg_meta.append({
			"name": a["name"],
			"type": a["type"],
			"def": default_args[i - first_default] if i >= first_default else null,
		})
	return arg_meta

# 执行命令，返回每条子命令的结果列表（元素 = 对应函数的返回值，如 CharSys.spawn 返回 Character）。
# 多条命令用 '\v' 分隔，结果按序一一对应；未找到的命令在对应位置放错误字符串。
static func execute(command_str: String) -> Array:
	var results: Array = []
	for single in command_str.split("\v"):
		var cmd: String = single.strip_edges()
		if cmd.is_empty():
			continue
		var parsed: Dictionary = CommandParser.parse(cmd)
		var name: String = parsed["name"]
		if not _commands.has(name):
			_lazy_load(name)
		var desc_raw: Variant = _commands.get(name)
		if desc_raw == null:
			var err: String = "No command: " + name
			print(err)
			results.append(err)
			continue
		var desc: Dictionary = desc_raw
		var callable: Callable = desc["callable"]
		results.append(callable.callv(_build_args(desc["arg_meta"], parsed)))
	return results


# 懒注册：命令形如 "类名.方法名"，据此定位并加载宿主类脚本，注册其命令。
static func _lazy_load(cmd_name: String) -> void:
	var dot := cmd_name.rfind(".")
	if dot <= 0:
		return
	var class_name_: String = cmd_name.substr(0, dot)
	var entries := ProjectSettings.get_global_class_list()
	var by_name := {}
	for e in entries:
		by_name[e["class"]] = e
	for cls in entries:
		if cls["class"] != class_name_:
			continue
		if not _descends_from(cls, "BaseClass", by_name):
			continue
		var script: GDScript = load(cls["path"])
		if script != null:
			_register_source_methods(class_name_, script)
		return


# 按反射参数元信息，把位置/命名参数组装成与方法签名顺序一致的全参数数组。
static func _build_args(arg_meta: Array, parsed: Dictionary) -> Array:
	var full: Array = []
	var positional: Array = parsed["positional"]
	var named: Dictionary = parsed["named"]
	for i in arg_meta.size():
		var meta: Dictionary = arg_meta[i]
		var key: String = meta["name"]
		var v: Variant
		if named.has(key):
			v = named[key]
		elif i < positional.size():
			v = positional[i]
		elif meta["def"] != null:
			v = meta["def"]
		else:
			v = _type_zero(meta["type"])
		full.append(_coerce(v, meta["type"]))
	return full


# 把解析出的 Variant 值，按反射到的目标参数类型强制转换。
# 例如 --tile_name 2 里的 "2" 会被解析成 int，但目标参数是 String，
# callv 不会隐式转换，这里统一转成正确类型。
static func _coerce(value: Variant, type: int) -> Variant:
	match type:
		TYPE_INT:
			if value is bool:
				return 1 if value else 0
			return int(value)
		TYPE_FLOAT:
			return float(value)
		TYPE_STRING:
			return value if value is String else str(value)
		TYPE_BOOL:
			if value is bool:
				return value
			if value is int:
				return value != 0
			if value is String:
				var s: String = value
				return s.to_lower() == "true"
			return bool(value)
		_:
			return value


static func _type_zero(type: int):
	match type:
		TYPE_INT:
			return 0
		TYPE_FLOAT:
			return 0.0
		TYPE_BOOL:
			return false
		TYPE_STRING:
			return ""
		TYPE_VECTOR2:
			return Vector2.ZERO
		_:
			return null
