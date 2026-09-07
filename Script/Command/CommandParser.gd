class_name CommandParser
extends BaseClass
# Godot 版命令解析器
# 用法:
#   CommandParser.parse("place 0 5 -10 门 2 -1 true")
#   -> { name="place", positional=[0,5,-10,"门",2,-1,true], named={} }
#   CommandParser.parse("place --layer_id 0 --x 10 --force_space")
#   -> { name="place", positional=[], named={layer_id:0, x:10, force_space:true} }
#
# 支持的数据类型（按判定优先级）:
#   - 静态引用  : $类名.成员$，如 $Test.test_int$（读该类的 static var / const 值）
#   - bool    : true / false（不区分大小写）
#   - int     : 整数，如 5 / -10 / 2
#   - float   : 小数，如 3.5 / -0.25
#   - String  : 其余全部按字符串处理；含空格的字符串可用双引号包裹，如 "a b c"
#
# 引用与转义（shell 风格）:
#   $Test.test_int$    -> 解析成 Test.test_int 的静态值
#   \$Test.test_int\$  -> 普通字符串 "$Test.test_int$"（\$ 表示字面 $，不作包裹符）
#   未成对包裹的普通字符串里的 \$ 也会还原成 $
#
# 参数形式:
#   - 位置参数  : 不带头，按序出现，对应命令签名
#   - 命名参数  : --name value（或 --name 结尾则视为 flag=true）
#   - flag      : --xxx（后无值）=> 值 true；命名参数用 -- 前缀（负数 -10 不视为参数名）

static var _class_scripts := {}   # class_name -> GDScript（懒缓存，供静态成员引用）

static func parse(input: String) -> Dictionary:
	input = input.strip_edges()
	if input.is_empty():
		input = "NOCOMMAND"
	var tokens := _tokenize(input)
	if tokens.is_empty():
		tokens = ["NOCOMMAND"]
	var name: String = tokens[0]
	tokens.remove_at(0)

	var positional: Array = []
	var named: Dictionary = {}
	var i := 0
	while i < tokens.size():
		var t: String = tokens[i]
		if t.begins_with("--"):
			var key: String = t.substr(2)
			# 下一个 token 存在且不是 -- 开头 => 作为该参数的值
			@warning_ignore("unsafe_method_access")
			if i + 1 < tokens.size() and not tokens[i + 1].begins_with("--"):
				named[key] = _convert(tokens[i + 1])
				i += 2
			else:
				named[key] = true   # flag，无值
				i += 1
		else:
			positional.append(_convert(t))
			i += 1

	return { "name": name, "positional": positional, "named": named }


static func _tokenize(input: String) -> Array:
	var tokens: Array = []
	var cur := ""
	var in_quote := false
	for ch in input:
		if ch == "\"":
			in_quote = not in_quote
			if not in_quote and cur != "":
				tokens.append(cur)
				cur = ""
		elif ch == " " and not in_quote:
			if cur != "":
				tokens.append(cur)
				cur = ""
		else:
			cur += ch
	if cur != "":
		tokens.append(cur)
	return tokens


static func _convert(raw: String):
	# $...$ 成对包裹且是纯引用（中间不含 $）→ 静态成员引用
	if raw.begins_with("$") and raw.ends_with("$") and raw.length() >= 3:
		var inner := raw.substr(1, raw.length() - 2)
		if not inner.contains("$"):
			var resolved := _try_resolve_member(inner)   # inner = "类名.成员"
			if resolved[0]:
				return resolved[1]
			return raw   # 读不到时保留原 token，便于排查
	var low := raw.to_lower()
	if low == "true":
		return true
	if low == "false":
		return false
	if raw.is_valid_int():
		return raw.to_int()
	if raw.is_valid_float():
		return raw.to_float()
	# 普通字符串：把 \$ 还原成字面 $
	return raw.replace("\\$", "$")


# 尝试读取 "类名.成员" 的值，返回 [ok: bool, value: Variant]。
# 先 script.get（static var），再试 const 表（const）。
static func _try_resolve_member(qualified: String) -> Array:
	var dot := qualified.find(".")
	var class_name_ := qualified.substr(0, dot)
	var member := qualified.substr(dot + 1)
	var script: GDScript = _find_class_script(class_name_)
	if script == null:
		return [false, null]
	var v: Variant = script.get(member)
	if v != null:
		return [true, v]
	var consts: Dictionary = script.get_script_constant_map()
	if consts.has(member):
		return [true, consts[member]]
	return [false, null]


# 按 class_name 找全局类脚本，结果懒缓存（找不到的类缓存 null，避免反复查）。
static func _find_class_script(class_name_: String) -> GDScript:
	if _class_scripts.has(class_name_):
		@warning_ignore("unsafe_cast")
		return _class_scripts[class_name_] as GDScript
	var found: GDScript = null
	for cls in ProjectSettings.get_global_class_list():
		if cls["class"] == class_name_:
			found = load(cls["path"])
			break
	_class_scripts[class_name_] = found
	return found
