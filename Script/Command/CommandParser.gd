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
#   - String  : 其余全部按字符串处理；含空格的字符串可用双引号包裹，如 "a b c"
#
# 参数形式:
#   - 位置参数  : 不带头，按序出现，对应命令签名
#   - 命名参数  : --name value（或 --name 结尾则视为 flag=true）
#   - flag      : --xxx（后无值）=> 值 true；命名参数用 -- 前缀（负数 -10 不视为参数名）

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
	var low := raw.to_lower()
	if low == "true":
		return true
	if low == "false":
		return false
	if raw.is_valid_int():
		return raw.to_int()
	if raw.is_valid_float():
		return raw.to_float()
	return raw
