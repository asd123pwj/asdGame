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

# ---- 两级解析缓存 ----
# L1：热缓存（LRU 双向链表），命中即移入表头；容量满时表尾降到 L2。
# L2：温缓存，用"时钟指针 + 时间桶"实现 O(1) 过期：
#   N 个桶排成环，每隔一个周期(秒)指针前进一格并清空该桶；
#   新项写入指针**下一个**桶（即"最新"桶），于是指针**当前**指向的桶就是最旧的一批。
#   桶数 N = ceil(TTL / 周期)，保证一项从写入到被清空恰好经历 TTL。
#   例：TTL=300s、周期=60s → 5 个桶，环形轮转，无需遍历扫描。
static var _l1: Dictionary = {}      # key -> plan（LRU 冷热数据）
static var _l1_prev: Dictionary = {} # key -> 前驱 key（LRU 链表）
static var _l1_next: Dictionary = {} # key -> 后继 key（LRU 链表）
static var _l1_tail: String = ""     # LRU 表尾（最久未用）
static var _l1_head: String = ""     # LRU 表头（最近使用）
static var _l2_ring: Array[Dictionary] = []  # 时间桶数组：每个桶是一个 Dictionary
static var _l2_index: Dictionary = {} # key -> 桶下标（O(1) 查询/计数，size() 即 L2 条目数）
static var _l2_hand: int = 0         # 时钟指针：指向"最旧"的桶（下次轮转时清空）
static var _l2_last_tick: float = 0.0 # 上次轮转时刻(秒)

static func parse(input: String) -> Dictionary:
	input = input.strip_edges()
	if input.is_empty():
		input = "NOCOMMAND"

	# 解析缓存：命中则跳过 _tokenize/_convert（含 $ 表达式）的全量解析。
	# $ 表达式被编译成"取值计划"缓存，只把定位过程固化，取值仍每次实时执行。
	# 可用 SysCfg.cache_command 整体关停。
	if Sys.sysCfg.cache_command:
		_l2_tick()
		var hit: Variant = _cache_get(input)
		if hit != null:
			@warning_ignore("unsafe_cast")
			return _run_plan(hit as Dictionary)
		var plan := _compile(input)
		_cache_put(input, plan)
		return _run_plan(plan)
	return _run_plan(_compile(input))

## 清空类脚本与两级解析缓存（热重载 / 调试用）。
static func clear_cache() -> void:
	_class_scripts.clear()
	_l1.clear()
	_l1_prev.clear()
	_l1_next.clear()
	_l1_head = ""
	_l1_tail = ""
	_l2_ring.clear()
	_l2_index.clear()
	_l2_hand = 0
	_l2_last_tick = 0.0


# ---------- 缓存读写 ----------

static func _cache_get(key: String) -> Variant:
	if _l1.has(key):
		_l1_touch(key)
		return _l1[key]
	if _l2_index.has(key):
		# L2 命中：提升回 L1（热数据回迁），并从桶中移除
		var bucket: Dictionary = _l2_ring[_l2_index[key]]
		var plan: Dictionary = bucket[key]
		bucket.erase(key)
		_l2_index.erase(key)
		_cache_put(key, plan)
		return plan
	return null

static func _cache_put(key: String, plan: Dictionary) -> void:
	if _l1.has(key) or _l2_has(key):
		return
	if _l1.size() >= Sys.sysCfg.cache_command_l1_capacity:
		_evict_l1_tail()
	_l1[key] = plan
	# 挂到链表表头（最近使用）
	_l1_prev[key] = ""
	_l1_next[key] = _l1_head
	if _l1_head != "":
		_l1_prev[_l1_head] = key
	_l1_head = key
	if _l1_tail == "":
		_l1_tail = key

# 命中 L1：移到表头（最近使用）。
static func _l1_touch(key: String) -> void:
	if _l1_head == key:
		return
	var prev: String = _l1_prev[key]
	var next: String = _l1_next[key]
	# 从链表摘除
	if prev != "":
		_l1_next[prev] = next
	else:
		_l1_head = next
	if next != "":
		_l1_prev[next] = prev
	else:
		_l1_tail = prev
	# 挂到表头
	_l1_prev[key] = ""
	_l1_next[key] = _l1_head
	if _l1_head != "":
		_l1_prev[_l1_head] = key
	_l1_head = key
	if _l1_tail == "":
		_l1_tail = key

# L1 满：表尾降级到 L2。
static func _evict_l1_tail() -> void:
	if _l1_tail == "":
		return
	var key := _l1_tail
	_l2_insert(key, _l1[key])
	var prev: String = _l1_prev[key]
	_l1.erase(key)
	_l1_prev.erase(key)
	_l1_next.erase(key)
	_l1_tail = prev
	if prev != "":
		_l1_next[prev] = ""
	else:
		_l1_head = ""


# ---------- L2 时间桶（时钟指针） ----------

# 轮转：指针前进，清空新指向的桶（即最旧的一桶）。按需触发，可能一次补多格。
static func _l2_tick() -> void:
	@warning_ignore("unsafe_property_access")
	var ttl: float = Sys.sysCfg.cache_command_l2_ttl
	@warning_ignore("unsafe_property_access")
	var period: float = maxf(Sys.sysCfg.cache_command_l2_period, 0.1)
	if ttl <= 0.0:
		_l2_clear()
		return
	# 桶数 = ceil(TTL / 周期)，至少 1
	var bucket_count: int = maxi(int(ceil(ttl / period)), 1)
	if _l2_ring.size() != bucket_count:
		_resize_ring(bucket_count)
		_l2_last_tick = _now()
		return
	var now := _now()
	if _l2_last_tick == 0.0:
		_l2_last_tick = now
		return
	var elapsed := now - _l2_last_tick
	if elapsed < period:
		return
	var steps := int(elapsed / period)
	_l2_last_tick += steps * period
	# 最多轮转整圈（再多也只是把仍有用的桶清空，无额外意义）
	if steps >= bucket_count:
		_l2_clear()
		return
	for i in steps:
		_l2_hand = (_l2_hand + 1) % bucket_count
		_l2_drop_bucket(_l2_hand)

## 清空指定桶，并同步删除索引。
static func _l2_drop_bucket(idx: int) -> void:
	var bucket: Dictionary = _l2_ring[idx]
	for key in bucket:
		_l2_index.erase(key)
	_l2_ring[idx] = {}

# 写入 L2：进入"最新"桶（指针的下一格），保证存活时间≈TTL。
static func _l2_insert(key: String, plan: Dictionary) -> void:
	@warning_ignore("unsafe_property_access")
	var cap: int = Sys.sysCfg.cache_command_max
	if cap <= 0:
		return
	if _l2_ring.is_empty():
		_resize_ring(1)
	# 总量上限：满了就先强推指针清一格
	while _l2_index.size() >= cap:
		_l2_hand = (_l2_hand + 1) % _l2_ring.size()
		_l2_drop_bucket(_l2_hand)
	var write_idx: int = (_l2_hand + 1) % _l2_ring.size()
	_l2_ring[write_idx][key] = plan
	_l2_index[key] = write_idx

static func _l2_has(key: String) -> bool:
	return _l2_index.has(key)

static func _l2_clear() -> void:
	for i in _l2_ring.size():
		_l2_ring[i] = {}
	_l2_index.clear()

# 重建桶数组：保留旧条目（并入新桶），避免配置变更丢失全部缓存。
static func _resize_ring(count: int) -> void:
	var old := _l2_ring
	_l2_ring = []
	for i in count:
		_l2_ring.append({})
	_l2_hand = 0
	_l2_index.clear()
	if not old.is_empty():
		for bucket in old:
			for key in bucket:
				_l2_insert(key, bucket[key])

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ---------- 编译 / 执行计划 ----------

## 把命令原文编译成"计划"。确定性部分（tokenize、字面量、$ 的定位）一次性固化；
## 运行时会变的部分（$ 的取值）留到 _run_plan 时执行。
static func _compile(input: String) -> Dictionary:
	# & 前缀 = 取值：整条命令是一个取值路径/表达式，直接求值返回其值。
	#   &Test.int1       读静态成员值
	#   &@ID.hp          读实例属性
	#   &Test.func(1)    调函数并把结果作为值
	if input.begins_with("&"):
		return { "is_value": true, "expr": _compile_expr("$" + input.substr(1)) }
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
				named[key] = _compile_arg(tokens[i + 1])
				i += 2
			else:
				named[key] = true   # flag，无值
				i += 1
		else:
			positional.append(_compile_arg(t))
			i += 1

	return { "is_value": false, "name": name, "positional": positional, "named": named }

## 执行计划，得到 parse() 的结果字典。
static func _run_plan(plan: Dictionary) -> Dictionary:
	if plan.get("is_value", false):
		@warning_ignore("unsafe_cast")
		var ev: Array = _run_expr(plan["expr"] as Dictionary)
		return { "is_value": true, "name": "", "value": ev[1] if ev[0] else null }
	var positional: Array = []
	for p in plan["positional"]:
		positional.append(_run_arg(p))
	var named: Dictionary = {}
	for key in plan["named"]:
		var p: Variant = plan["named"][key]
		named[key] = _run_arg(p)
	return { "is_value": false, "name": plan["name"], "positional": positional, "named": named }

## 编译一个参数：字面量直接固化；$ 表达式编译成子计划。
## 计划用 dict 表示：{ "lit": true, "value": ... } 或 { "lit": false, "expr": {...} }
static func _compile_arg(raw: String) -> Dictionary:
	if raw.begins_with("$") and not raw.begins_with("\\$"):
		return { "lit": false, "expr": _compile_expr(raw) }
	return { "lit": true, "value": _convert_literal(raw) }

## 执行一个参数计划。
## 注意：named 里的"无值 flag"直接存的是 bool true（非计划字典），要原样返回。
static func _run_arg(p: Variant) -> Variant:
	@warning_ignore("unsafe_method_access")
	if p is Dictionary and p.has("lit"):
		if p["lit"]:
			return p["value"]
		@warning_ignore("unsafe_cast")
		var ev: Array = _run_expr(p["expr"] as Dictionary)
		return ev[1] if ev[0] else null
	return p


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


# ---------- $ 表达式的编译 / 执行 ----------
# 计划用 dict 表示，把"定位"固化下来，运行时只做必需的最后一步取值：
#   { "kind": "instance", "id": int, "ops": [...] }              $@ID.<ops>
#   { "kind": "member", "owner": String(类名), "ops": [...] }     $类.<成员链>
#   { "kind": "func", "callable": Callable, "args": [<plan>...] } $类.函数(...)
#   { "kind": "literal", "value": Variant }                      字面量（函数/方法参数）
# ops 每项：
#   { "op": "field", "name": String }            .名称
#   { "op": "index", "idx": int }                [n]
#   { "op": "method", "name": String, "args": [<plan>...] }  .名称(...)

## 编译一个以 "$" 开头的表达式。
static func _compile_expr(s: String) -> Dictionary:
	var body := s.substr(1)   # 去掉前导 $
	# 实例访问：$@ID.成员 或 $@ID.方法(...)
	if body.begins_with("@"):
		var inst_expr := body.substr(1)
		var id_res := _chain_id(inst_expr)
		if not id_res[0]:
			return { "kind": "invalid" }
		return { "kind": "instance", "id": id_res[1], "ops": _compile_ops(_chain_rest(inst_expr)) }
	# 找第一个 "(" 判断是否为函数调用
	var paren := _find_top_level_paren(body)
	if paren < 0:
		# 纯读值：成员链。定位"宿主"到第一个 '.' 之前（类名或静态成员），之后交给 ops。
		var dot := body.find(".")
		var head := body if dot < 0 else body.substr(0, dot)
		var rest := "" if dot < 0 else body.substr(dot)
		return { "kind": "member", "owner": head, "ops": _compile_ops(rest) }
	# 函数调用：定位静态函数（Callable 固化），参数编译成子计划
	var func_expr := body.substr(0, paren)
	var args_str := body.substr(paren + 1, body.rfind(")") - paren - 1)
	var resolved_func := _try_resolve_method(func_expr)
	if not resolved_func[0]:
		return { "kind": "invalid" }
	var arg_plans: Array = _compile_args(args_str)
	return { "kind": "func", "callable": resolved_func[1], "args": arg_plans }

## 执行已编译的表达式计划，返回 [ok, value]。
static func _run_expr(plan: Dictionary) -> Array:
	match plan.get("kind", ""):
		"instance":
			var obj := instance_from_id(plan["id"])
			if obj == null:
				return [false, null]
			return _run_ops(obj, plan["ops"])
		"member":
			return _run_member(plan["owner"], plan["ops"])
		"func":
			var callable: Callable = plan["callable"]
			var args: Array = []
			for ap in plan["args"]:
				var av := _run_expr(ap)
				if not av[0]:
					return [false, null]
				args.append(av[1])
			return [true, callable.callv(args)]
		"literal":
			return [true, plan["value"]]
		_:
			return [false, null]

## 拆分 "$@ID.<...>" 得到 <...> 部分（去掉 ID）。
static func _chain_rest(inst_expr: String) -> String:
	var i := 0
	while i < inst_expr.length() and inst_expr[i] != "." and inst_expr[i] != "[" and inst_expr[i] != "(":
		i += 1
	return inst_expr.substr(i)

## 取 "$@ID.<...>" 里的 ID，返回 [ok, id]。
## 注意：不能用 is_valid_int()——实例 ID 是 64 位且可能为负，is_valid_int() 按 int32 校验会误判；
## 也不能用负数当"无效"哨兵（合法 ID 本身就可能为负），故用 [ok, id] 返回。
static func _chain_id(inst_expr: String) -> Array:
	var i := 0
	var id_str := ""
	# 允许前导负号（get_instance_id() 的 64 位值高位为 1 时 str() 会带 "-"）
	if i < inst_expr.length() and inst_expr[i] == "-":
		id_str += "-"
		i += 1
	while i < inst_expr.length():
		var c := inst_expr[i]
		if c == "." or c == "[" or c == "(":
			break
		if c < "0" or c > "9":
			return [false, 0]
		id_str += c
		i += 1
	if id_str.is_empty() or id_str == "-":
		return [false, 0]
	return [true, int(id_str)]

## 编译成员链（<...> 部分）为 ops 数组。
static func _compile_ops(rest: String) -> Array:
	var ops: Array = []
	var i := 0
	while i < rest.length():
		var c := rest[i]
		if c == ".":
			i += 1
			var seg := ""
			while i < rest.length() and rest[i] != "." and rest[i] != "[" and rest[i] != "(":
				seg += rest[i]
				i += 1
			if i < rest.length() and rest[i] == "(":
				var args_end := _match_paren(rest, i)
				var args_str := "" if args_end < 0 else rest.substr(i + 1, args_end - i - 1)
				ops.append({ "op": "method", "name": seg, "args": _compile_args(args_str) })
				i = (args_end + 1) if args_end >= 0 else rest.length()
			else:
				ops.append({ "op": "field", "name": seg })
		elif c == "[":
			i += 1
			var num := ""
			if i < rest.length() and rest[i] == "-":
				num += "-"
				i += 1
			while i < rest.length() and rest[i] >= "0" and rest[i] <= "9":
				num += rest[i]
				i += 1
			if num.is_empty() or num == "-" or i >= rest.length() or rest[i] != "]":
				break   # 下标格式非法，停止解析（后续访问器一并放弃）
			i += 1
			ops.append({ "op": "index", "idx": int(num) })
		else:
			break
	return ops

## 编译参数串 "a, b, $x" 为计划数组。
static func _compile_args(args_str: String) -> Array:
	var plans: Array = []
	for ap_raw in _split_top_level_args(args_str):
		var ap: String = ap_raw
		ap = ap.strip_edges()
		if ap.is_empty():
			continue
		if ap.begins_with("$") and not ap.begins_with("\\$"):
			plans.append(_compile_expr(ap))
		else:
			plans.append({ "kind": "literal", "value": _convert_literal(ap) })
	return plans

## 对已取到的宿主值执行成员链 ops。
static func _run_ops(v: Variant, ops: Array) -> Array:
	for op in ops:
		match op["op"]:
			"field":
				if v is GDScript:
					# 类脚本：先当静态属性读，读不到再查常量表（const 不在属性列表里）
					var s: GDScript = v
					if op["name"] in s:
						v = s.get(op["name"])
					else:
						var consts: Dictionary = s.get_script_constant_map()
						if not consts.has(op["name"]):
							return [false, null]
						v = consts[op["name"]]
				elif v is Object:
					var obj: Object = v
					if not op["name"] in obj:
						return [false, null]
					v = obj.get(op["name"])
				elif v is Dictionary:
					var d: Dictionary = v
					if not d.has(op["name"]):
						return [false, null]
					v = d[op["name"]]
				else:
					return [false, null]
			"index":
				if not (v is Array):
					return [false, null]
				var arr: Array = v
				var n: int = op["idx"]
				if n < 0 or n >= arr.size():
					return [false, null]
				v = arr[n]
			"method":
				if not (v is Object):
					return [false, null]
				var obj2: Object = v
				if not obj2.has_method(op["name"]):
					return [false, null]
				var args: Array = []
				for ap in op["args"]:
					var av := _run_expr(ap)
					if not av[0]:
						return [false, null]
					args.append(av[1])
				v = obj2.callv(op["name"], args)
			_:
				return [false, null]
	return [true, v]

## 执行 "$类.<成员链>"：取类脚本作为静态宿主，再走 ops。
static func _run_member(owner: String, ops: Array) -> Array:
	# $ 表达式的宿主只支持类名（$类名.xxx），取类脚本后走 ops
	var script := _find_class_script(owner)
	if script == null:
		return [false, null]
	return _run_ops(script, ops)


# 找到从 start（指向 '('）开始配对的 ')' 下标；未匹配返回 -1。
static func _match_paren(s: String, start: int) -> int:
	var depth := 0
	for j in range(start, s.length()):
		if s[j] == "(":
			depth += 1
		elif s[j] == ")":
			depth -= 1
			if depth == 0:
				return j
	return -1


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
	# 不用 is_valid_int()（按 int32 校验，64 位整数会误判），改为手写 64 位整数判定
	if _is_int_literal(raw):
		return int(raw)
	if raw.is_valid_float():
		return raw.to_float()
	var s := raw.replace("\\$", "$")
	# 去掉成对双引号包裹（函数/命令的字符串参数）
	if s.length() >= 2 and s.begins_with("\"") and s.ends_with("\""):
		return s.substr(1, s.length() - 2)
	return s


## 判定是否为十进制整数（支持前导 +/-，不限 32 位）。
static func _is_int_literal(raw: String) -> bool:
	if raw.is_empty():
		return false
	var i := 0
	if raw[0] == "+" or raw[0] == "-":
		i = 1
	if i >= raw.length():
		return false
	while i < raw.length():
		var c := raw[i]
		if c < "0" or c > "9":
			return false
		i += 1
	return true


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
