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
#   - bool    : true / false（不区分大小写）
#   - int     : 整数，如 5 / -10 / 2
#   - float   : 小数，如 3.5 / -0.25
#   - 表达式  : 以 $ 前缀，读值或调函数
#   - String  : 其余全部按字符串处理；含空格的字符串可用双引号包裹，如 "a b c"
#
# $ 前缀表达式（读到空白/参数分隔/命令结束处自然终止，无需成对闭合）:
#   $Test.test_int                    读静态 var/const 的值
#   $Test.test_int.value              读后取字典键 .value
#   $Test.test_int[0].value[0].value  再取列表下标 [n] / 字典 .key（链式）
#   $Test.test_func($Test.int1, -1)   调静态函数，参数用括号逗号分隔，可递归 $ 表达式
#   $Test.test_func($Test.test_int[0].value[0].value, "s")  嵌套读值 / 字符串参数
#
# 转义:
#   \$                           普通字符串里的字面 $（\$ 还原成 $，不作表达式前缀）
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


# 分词。
#  - 顶层空格切分 token；
#  - 括号内的空格并入（使函数调用 $Test.func($Test.int1, -1) 保持整体）；
#  - 顶层双引号成对包裹的字符串作为单 token 且去掉引号。
static func _tokenize(input: String) -> Array:
	var tokens: Array = []
	var cur := ""
	var in_quote := false
	var depth := 0
	var quote_at_top := false   # 引号是否从顶层开始（决定闭合时是否去掉引号）
	for ch in input:
		if ch == "\"":
			if not in_quote:
				in_quote = true
				quote_at_top = depth == 0
				if not quote_at_top:
					cur += ch   # 括号内的引号原样保留（表达式字符串参数）
			else:
				in_quote = false
				if quote_at_top:
					if cur != "":
						tokens.append(cur)   # 顶层字符串去引号后成 token
						cur = ""
				else:
					cur += ch   # 表达式内闭合引号，原样保留
		elif ch == "(" or ch == "[":
			depth += 1
			cur += ch
		elif ch == ")" or ch == "]":
			depth -= 1
			cur += ch
		elif ch == " ":
			if not in_quote and depth == 0:
				if cur != "":
					tokens.append(cur)
					cur = ""
			else:
				cur += ch
		else:
			cur += ch
	if cur != "":
		tokens.append(cur)
	return tokens


static func _convert(raw: String):
	# $ 前缀表达式（读值或函数调用），如 $Test.test_int[0].value 或 $Test.test_func($Test.int1, -1)
	if raw.begins_with("$"):
		if raw.begins_with("\\$"):
			# \$ 是字面 $ 的转义，去掉反斜杠后当普通字符串处理
			return raw.replace("\\$", "$")
		var eval := _eval_expr(raw)
		if eval[0]:
			return eval[1]
		return raw   # 表达式失败时保留原 token，便于排查
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


# 求值一个以 "$" 开头的表达式，返回 [ok, value]。
# 形式：
#   $类名.成员链             读值（如 $Test.test_int[0].value[0].value）
#   $类名.函数(参数, ...)    调函数（参数可用逗号分隔、可递归 $ 表达式，如 $Test.test_func($Test.int1, -1)）
static func _eval_expr(s: String) -> Array:
	var body := s.substr(1)   # 去掉前导 $
	# 找第一个 "(" 判断是否为函数调用
	var paren := _find_top_level_paren(body)
	if paren < 0:
		# 纯读值：成员链
		return _try_resolve_member(body)
	# 函数调用
	var func_expr := body.substr(0, paren)
	var args_str := body.substr(paren + 1, body.rfind(")") - paren - 1)
	var resolved_func := _try_resolve_method(func_expr)
	if not resolved_func[0]:
		return [false, null]
	# 递归求值每个参数
	var arg_parts := _split_top_level_args(args_str)
	var args: Array = []
	for ap_raw in arg_parts:
		var ap: String = ap_raw
		var trimmed := ap.strip_edges()
		if trimmed.is_empty():
			continue
		var av := _eval_arg(trimmed)
		if not av[0]:
			return [false, null]
		args.append(av[1])
	var callable: Callable = resolved_func[1]
	return [true, callable.callv(args)]


# 求值一个参数：可能是 $ 表达式、数字、bool，或裸字符串。
static func _eval_arg(s: String) -> Array:
	if s.begins_with("$") and not s.begins_with("\\$"):
		return _eval_expr(s)
	return [true, _convert_literal(s)]


# 在 body 中找第一个不处于嵌套括号内的 "(" 的索引；无则 -1。
static func _find_top_level_paren(body: String) -> int:
	var depth := 0
	for i in body.length():
		var c := body[i]
		if c == "(":
			if depth == 0:
				return i
			depth += 1
		elif c == ")":
			depth -= 1
	return -1


# 把括号内参数字符串按逗号拆分成顶层项（忽略嵌套括号/引号内的逗号）。
static func _split_top_level_args(args_str: String) -> Array:
	var parts: Array = []
	var cur := ""
	var depth := 0
	var in_quote := false
	for c in args_str:
		if c == "\"":
			in_quote = not in_quote
			cur += c
		elif in_quote:
			cur += c
		elif c == "(" or c == "[":
			depth += 1
			cur += c
		elif c == ")" or c == "]":
			depth -= 1
			cur += c
		elif c == "," and depth == 0:
			parts.append(cur)
			cur = ""
		else:
			cur += c
	if cur != "":
		parts.append(cur)
	return parts


# 普通字面量：bool / int / float / 字符串。
static func _convert_literal(raw: String):
	var low := raw.to_lower()
	if low == "true":
		return true
	if low == "false":
		return false
	if raw.is_valid_int():
		return raw.to_int()
	if raw.is_valid_float():
		return raw.to_float()
	var s := raw.replace("\\$", "$")
	# 去掉成对双引号包裹（函数/命令的字符串参数）
	if s.length() >= 2 and s.begins_with("\"") and s.ends_with("\""):
		return s.substr(1, s.length() - 2)
	return s


# 取一个可调用的静态方法，返回 [ok, Callable]。
# func_expr 形如 "类名.静态方法"，如 "Test.test_func"。
static func _try_resolve_method(func_expr: String) -> Array:
	var dot := func_expr.find(".")
	if dot <= 0 or dot == func_expr.length() - 1:
		return [false, null]
	var class_name_ := func_expr.substr(0, dot)
	var method := func_expr.substr(dot + 1)
	if method.is_empty() or method.contains(".") or method.contains("[") or method.contains("("):
		return [false, null]   # 仅支持 "类.静态方法"
	var script: GDScript = _find_class_script(class_name_)
	if script == null:
		return [false, null]
	return [true, Callable(script, method)]


# 解析引用链，返回 [ok: bool, value: Variant]。
# 支持 类名.静态成员  后跟一串访问器：
#   .键       取 Dictionary 的键（如 .value）
#   [数字]    取 Array 的下标（如 [0]）
# 例：Test.test_int.value[0]  -> 读 Test.test_int，再 .value 再 [0]
static func _try_resolve_member(expr: String) -> Array:
	var dot := expr.find(".")
	if dot <= 0:
		return [false, null]
	var class_name_ := expr.substr(0, dot)
	var chain := expr.substr(dot + 1)   # 形如 "test_int.value[0]"

	# 第一个成员名：读到下一个 "." 或 "[" 之前
	var member := ""
	var i := 0
	while i < chain.length() and chain[i] != "." and chain[i] != "[":
		member += chain[i]
		i += 1
	if member.is_empty():
		return [false, null]
	var rest := chain.substr(i)         # 剩余访问器，如 ".value[0]" 或 ""

	var script: GDScript = _find_class_script(class_name_)
	if script == null:
		return [false, null]
	var v: Variant = script.get(member)
	if v == null:
		var consts: Dictionary = script.get_script_constant_map()
		if not consts.has(member):
			return [false, null]
		v = consts[member]
	return _apply_accessors(v, rest)


# 依次应用 ".键" 与 "[数字]" 访问器，返回 [ok, value]。
static func _apply_accessors(v: Variant, rest: String) -> Array:
	var i := 0
	while i < rest.length():
		if rest[i] == ".":
			i += 1
			var key := ""
			while i < rest.length() and _is_key_char(rest[i]):
				key += rest[i]
				i += 1
			if key.is_empty() or not (v is Dictionary):
				return [false, null]
			var dict: Dictionary = v
			if not dict.has(key):
				return [false, null]
			v = dict[key]
		elif rest[i] == "[":
			i += 1
			var num := ""
			while i < rest.length() and rest[i] >= "0" and rest[i] <= "9":
				num += rest[i]
				i += 1
			if i >= rest.length() or rest[i] != "]":
				return [false, null]
			i += 1
			if not (v is Array) or num.is_empty():
				return [false, null]
			var arr: Array = v
			var n := num.to_int()
			if n < 0 or n >= arr.size():
				return [false, null]
			v = arr[n]
		else:
			return [false, null]
	return [true, v]


static func _is_key_char(c: String) -> bool:
	return c == "_" or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


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
