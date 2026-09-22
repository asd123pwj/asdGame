## 指令 = **一行一个表达式**（解析在 CommandParser，本类负责"查命令 + 组参数 + 调用"）。
## 继承于 BaseClass 的类的**静态方法**可作为指令：命令名就是 `类名.方法名`。
##     class_name Test
##     static var test_int := [{"value": [{"value": 5}]}] # [0].value[0].value
##     static var test_int2 := {"value": [-10]}
##     static var a := 0
##     static func test_func(a: int, b: int) -> int:
##		   return a + b
##     var char_a := Character.new()
## **命令调用**（位置参数 + 关键字参数；没写的参数用签名里的默认值，可跳着给）：
##     Msg.send_cmd('MapSys.place(0, 5, -10, "门", 2, -1, true)')
##	   Msg.send_cmd("MapSys.place(layer_id=0, x=10, source_name=\"门\", tile_name=2, force_space=true)")
##     Msg.send_cmd("UIInteract.open(@UI/MiniHUD, \"Menu\", @UI/MiniHUD, close_on_blur=true)")
## 参数里引用变量/函数（直接写取值链，链式：字典 .key、数组 [index]、函数 ()）：
##     Msg.send_cmd("MapSys.place(Test.a, 5, -10, \"门\", 2, -1, true)")
##     Msg.send_cmd("MapSys.place(0, Test.test_func(Test.a, 4), Test.test_int2.value[0], \"门\", 2, -1, true)")
## **取值一行**（拿值，不一定调用）：末尾带 () 就"调完拿返回值"，不带 () 就取这个值本身：
##     Msg.send_cmd("Test.a")                     读静态变量
##     Msg.send_cmd("@self.control.text")          读实例属性（`@self` 由指令系统解析）
##     Msg.send_cmd("UISys.get_ui(\"MiniHUD\").refresh(\"content\")")   取值链末尾带 () = 调用
## 用实例：把"类名"换成 `@注册名`，其它一样：
##     Msg.send_cmd("@678965479816.hp")
## send_cmd 返回的是"每行结果"的数组，取值再按下标：
##     Msg.send_cmd("Test.a")[0]                  单行：取该行的结果
##     Msg.send_cmd("CharSys.spawn(\"人类\")")[0]  单行：取该行的结果
##
## **「任意配置键」约定**（开放式配置的命令怎么收参数）：
## 方法签名里有**叫 `config` 的参数**时，调用里凡是**没对上任何参数名**的命名参数，都塞进它（键名照抄）：
##     UIInteract.open(@host, "Editor", @host, host=@host, content_cmd="host.config", size=[310, 210])
##     #        ↑ 对上签名                ↑ 对上签名                ↑ 不在签名里 ⇒ config["size"]
## 显式写的 `config={…}` 与这些键**合并**（指令里直接写的覆盖字典里同名的）；位置参数不进 config（照旧按序落槽）。
## 用途：元素的 config 是**开放集合**（谁都能加键），这样"打开时实时给任意 config 键"不必拼字典。
## **代价**：没对上的名字不再报"参数名不存在"（`siz=[1,2]` 会静默变成 `config["siz"]`）——
## 所以**只有确实想要开放式配置的命令才加 `config` 参数**；参数固定的命令别加，保住它的报错能力。
## 实现：_build_args（"config" 那一段）。默认值 `{}` 用不得（GDScript 里字典默认值是共享的）——
## 要就写 `config: Variant = null` 再在里面判 `is Dictionary`。
class_name CmdSys
extends BaseClass
## 指令系统：把字符串指令变成方法调用（解析在 CommandParser，本类负责"找命令 + 组参数 + 调用"）。
## 命令 = "类名.静态方法名(参数)"，参数用 `(…)` 包住：位置参数 + `名字=值`（可跳过带默认值的参数）。
## 私有方法（`_` 开头）**也照常注册**为命令（有意为之，见 _register_source_methods）。
## 被谁用：Msg.send_cmd（唯一入口，落到 MessageHub 的 COMMAND → 本类 execute）。


## 命令表：cmd_name -> { callable, arg_meta, arg_index }（arg_index = 参数名 → 下标，注册时算一次）。
## 被谁用：execute（查）、_register_source_methods（写）、_lazy_load。
static var _commands: Dictionary = {}   # cmd_name -> { callable, arg_meta, arg_index }

## 源缓存：BaseClass 后代的脚本 + 它的命令前缀（见 _all_sources）。
## ProjectSettings.get_global_class_list() 每次都会新建数组，而 _lazy_load 会在"命令表里没有"时被调，
## 所以整张表只扫一遍、结果缓存在这里；clear_cache 里清。
static var _sources: Array = []
static var _sources_ready := false
## 懒注册过的前缀：同一个前缀不重复全扫（一个前缀的所有文件第一次就都收进来了）。
static var _loaded_prefixes: Dictionary = {}

## 「命令前缀组」：**约定常量的名字**（注意：这不是"本类的前缀"——CmdSys 的前缀就是它自己的类名，
## 它不需要声明这个常量）。谁会用到它：一个命令宿主按功能拆成多个文件时（交互就是这样：名字多、又散），
## 在基类写一次 `const CMD_HOST := "UIInteract"`，那一组文件就都注册成 `UIInteract.xxx`：
##   UIInteractBase.gd（声明一次）、UIInteract_OpenClose.gd、UIInteract_Drag.gd …
## **只做一件事、也不拆文件的系统别写它**：前缀默认就是类名（如 `CmdSys` / `Utils` / `MapSys`）。
const CMD_HOST_CONST := "CMD_HOST"


# 初始化（幂等）：注册命令 + 监听消息总线的 "COMMAND"。
# 由系统启动时 new 一次触发，例如 SystemManager.init_sub_system() 里 CmdSys.new()。
func _init() -> void:
	if not Sys.sysCfg.lazy_command_registration:
		_scan_all_sources()
	Msg.listen_cmd(
		func(message: Variant) -> Variant:
			return execute(str(message))
	)


# 扫一遍全局类表，挑出所有**最终继承 BaseClass** 的源（含间接继承），缓存脚本与命令前缀。
# 返回 [{ class: 类名, script: GDScript, host: 命令前缀 }]。整表只扫一次（clear_cache 里失效）。
# 被谁用：_scan_all_sources、_lazy_load。
static func _all_sources() -> Array:
	if _sources_ready:
		return _sources
	_sources_ready = true
	var entries := ProjectSettings.get_global_class_list()
	var by_name := {}
	for e in entries:
		by_name[e["class"]] = e
	for cls in entries:
		if not _descends_from(cls, "BaseClass", by_name):
			continue
		var script: GDScript = load(cls["path"])
		if script == null:
			continue
		_sources.append({ "class": cls["class"], "script": script, "host": _cmd_host(script, cls["class"]) })
	return _sources


# 把所有命令源的静态方法注册为命令（非懒注册模式：_init 里调一次）。
# 被谁用：_init。
static func _scan_all_sources() -> void:
	for src in _all_sources():
		_register_source_methods(src)


# 判断某个全局类记录（entry）是否最终继承自 root_name（沿 base 链上溯）。
# get_global_class_list 的 "base" 只给直接父类名，需递归查祖先。
# 被谁用：_scan_all_sources、_lazy_load。
static func _descends_from(entry: Dictionary, root_name: String, by_name: Dictionary) -> bool:
	var cur: Dictionary = entry
	while cur.has("base") and cur["base"] != "":
		if cur["base"] == root_name:
			return true
		if not by_name.has(cur["base"]):
			break   # base 是未注册的类（如内置类）或链断了
		cur = by_name[cur["base"]]
	return false


# 把某个命令源里的静态方法注册为命令（src 见 _all_sources）。
# 私有方法（`_` 开头）**照常注册**：私有只是写法习惯，想调就调，不调也只是表里多一条（有意为之）。
# 被谁用：_scan_all_sources、_lazy_load。
static func _register_source_methods(src: Dictionary) -> void:
	var prefix: String = src["host"]
	var script: GDScript = src["script"]
	for m_raw in script.get_script_method_list():
		var m: Dictionary = m_raw
		var method_name: String = m["name"]
		# 只收 static（get_script_method_list 的 flags 含 METHOD_FLAG_STATIC）
		if m.get("flags", 0) & METHOD_FLAG_STATIC == 0:
			continue
		var arg_meta: Array = _make_arg_meta(m)
		# 参数名 → 下标：注册时算一次，组装参数时 O(1) 查（不再每次线性找一遍）
		var arg_index: Dictionary = {}
		for i in arg_meta.size():
			arg_index[str(arg_meta[i]["name"])] = i
		_commands[prefix + "." + method_name] = {
			"callable": Callable(script, method_name),
			"arg_meta": arg_meta,
			"arg_index": arg_index,
		}


# 取某个命令源脚本要注册到哪个前缀下：脚本（或它的基类）写了 `const CMD_HOST := "xxx"` 就用它，
# 否则用类名自己（见 CMD_HOST_CONST 的说明）。**沿继承链找**，所以前缀可以只在基类声明一次。
# 被谁用：_register_source_methods、_lazy_load（判断某个前缀该收拢哪些文件）。
static func _cmd_host(script: GDScript, fallback: String) -> String:
	var s: GDScript = script
	while s != null:
		var host: Variant = s.get_script_constant_map().get(CMD_HOST_CONST)
		if host != null and not str(host).is_empty():
			return str(host)
		s = s.get_base_script()
	return fallback


# 从反射到的方法信息构造参数元信息数组。
# default_args 只含末尾若干有默认值的参数，按位对齐补到对应参数，
# 因此省略某参数时会自动用方法签名里写的默认值（如 variant=-1）。
# 被谁用：_register_source_methods。
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
# 被谁用：_init 注册的 COMMAND 监听（即 Msg.send_cmd 的落地）。
static func execute(command_str: String) -> Array:
	var results: Array = []
	for cmd in CommandParser.split_lines(command_str):
		# 拆行、解析（含取值链定位）都在 CommandParser 的缓存里；
		# 这里只做"查命令 + 组装参数 + 调用"，不再另设执行缓存。
		var parsed: Dictionary = CommandParser.parse(str(cmd))
		if parsed.get("is_value", false):
			results.append(parsed.get("value"))
			continue
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
		results.append(callable.callv(_build_args(desc["arg_meta"], desc["arg_index"], parsed["args"])))
	return results


# 清空缓存（热重载 / 调试用）。
# 被谁用：手动调用（调试）。
static func clear_cache() -> void:
	CommandParser.clear_cache()
	_sources.clear()
	_sources_ready = false
	_loaded_prefixes.clear()


# 懒注册：命令形如 "类名.方法名"，据此在源缓存里找出提供这个前缀的源并注册。
# 前缀可能由**多个文件**提供（命令前缀组，见 CMD_HOST_CONST）：类名正好等于前缀的（如 UIInteract.gd）、
# 以及写了 `const CMD_HOST` 挂到此前缀下的（如 UIInteract_Drag.gd），两类一起收。
# 同一个前缀只扫一次：第一次就把该前缀的所有文件都收进来了（_loaded_prefixes）。
# 被谁用：execute（命令表里没有时）。
static func _lazy_load(cmd_name: String) -> void:
	var dot := cmd_name.rfind(".")
	if dot <= 0:
		return
	var prefix: String = cmd_name.substr(0, dot)
	if _loaded_prefixes.has(prefix):
		return
	_loaded_prefixes[prefix] = true
	for src in _all_sources():
		if src["class"] == prefix or src["host"] == prefix:
			_register_source_methods(src)


# 按反射参数元信息，把"位置参数 + 名字=值"组装成与方法签名顺序一致的全参数数组。
# 规则（与 Python 一致）：位置参数**按序落到还没填的槽**；`名字=值` 落到名字对应的槽（可跳过中间的参数）；
# 都没给的用方法默认值，最后兜零值。位置参数写在命名参数之后、名字不存在、参数给重了都给一声警告。
# arg_index = 参数名 → 下标（注册时算好，见 _register_source_methods）。
# 被谁用：execute。
static func _build_args(arg_meta: Array, arg_index: Dictionary, args: Array) -> Array:
	# 快路：全是位置参数（最常见的写法）——按序落槽、后面取默认值，不必建 slots/filled 两张表
	var all_positional := true
	for a_raw in args:
		@warning_ignore("UNSAFE_CAST")
		if str((a_raw as Dictionary)["name"]) != "":
			all_positional = false
			break
	if all_positional:
		if args.size() > arg_meta.size():
			push_warning("CmdSys: %s 的参数太多了（多出来的被忽略）" % str(arg_meta.size()))
		var quick: Array = []
		for i in arg_meta.size():
			var meta: Dictionary = arg_meta[i]
			@warning_ignore("UNSAFE_CAST")
			var v: Variant = (args[i] as Dictionary)["value"] if i < args.size() else meta["def"]
			quick.append(_coerce(v, meta["type"]))
		return quick
	# **任意 config 键**：方法签名里有 `config` 参数时，凡是**没对上任何参数名**的命名参数都塞进它
	# （键名照抄），于是"打开时实时给这个元素的任意 config 键"能直接写在指令里，不必拼字典：
	#   UIInteract.open(@host, "Editor", @host, host=@host, content_cmd="host.config", size=[300, 200])
	# 显式写的 `config={…}` 与这些键**合并**（指令里直接写的那个覆盖字典里同名的）。
	# 只有"有 config 参数"的方法才有这个口子，别的命令仍按老规矩（名字不存在就警告）。
	if arg_index.has("config"):
		var extras: Dictionary = {}
		var kept: Array = []
		var explicit_cfg: Variant = null
		for a_raw in args:
			var a: Dictionary = a_raw
			var nm: String = str(a["name"])
			if nm == "config":
				explicit_cfg = a["value"]
			elif nm != "" and not arg_index.has(nm):
				extras[nm] = a["value"]
			else:
				kept.append(a)
		if not extras.is_empty() or explicit_cfg is Dictionary:
			var merged: Dictionary = {}
			if explicit_cfg is Dictionary:
				merged = (explicit_cfg as Dictionary).duplicate()
			merged.merge(extras, true)
			kept.append({ "name": "config", "value": merged })
		args = kept
	var slots: Array = []
	var filled: Array = []
	for i in arg_meta.size():
		slots.append(null)
		filled.append(false)
	var next_pos := 0
	var seen_named := false
	for a_raw in args:
		var a: Dictionary = a_raw
		var arg_name: String = str(a["name"])
		if arg_name == "":
			if seen_named:
				push_warning("CmdSys: 位置参数不能写在命名参数后面（%s 被忽略）" % str(a["value"]))
				continue
			while next_pos < slots.size() and filled[next_pos]:
				next_pos += 1
			if next_pos >= slots.size():
				push_warning("CmdSys: %s 的参数太多了（多出来的被忽略）" % str(arg_meta.size()))
				continue
			slots[next_pos] = a["value"]
			filled[next_pos] = true
			next_pos += 1
			continue
		seen_named = true
		var idx: int = arg_index.get(arg_name, -1)
		if idx < 0:
			push_warning("CmdSys: 没有参数名「%s」（有效名见方法签名）" % arg_name)
			continue
		if filled[idx]:
			push_warning("CmdSys: 参数「%s」给了两次（用后给的那个）" % arg_name)
		slots[idx] = a["value"]
		filled[idx] = true
	var full: Array = []
	for i in arg_meta.size():
		var meta: Dictionary = arg_meta[i]
		var v: Variant = slots[i] if filled[i] else meta["def"]
		full.append(_coerce(v, meta["type"]))
	return full


# 把解析出的值，按反射到的目标参数类型转换；**value 为 null**（参数没给、方法也没默认值）时给该类型的零值。
# 例如 tile_name=2 里的 2 会被解析成 int，但目标参数是 String，callv 不会隐式转换，这里统一转成正确类型。
# 被谁用：_build_args。
static func _coerce(value: Variant, type: int) -> Variant:
	match type:
		TYPE_INT:
			if value == null:
				return 0
			if value is bool:
				return 1 if value else 0
			return int(value)
		TYPE_FLOAT:
			return 0.0 if value == null else float(value)
		TYPE_STRING:
			if value == null:
				return ""
			return value if value is String else str(value)
		TYPE_BOOL:
			if value == null:
				return false
			if value is bool:
				return value
			if value is int:
				return value != 0
			if value is String:
				var s: String = value
				return s.to_lower() == "true"
			return bool(value)
		TYPE_VECTOR2:
			return Vector2.ZERO if value == null else value
		_:
			return value
