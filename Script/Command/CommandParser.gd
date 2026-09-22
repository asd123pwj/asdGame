class_name CommandParser
extends BaseClass
# Godot 版命令解析器
# 用法:
#   CommandParser.parse("MapSys.place(0, 5, -10, \"门\", 2, -1, true)")
#   -> { is_value=false, name="MapSys.place", args=[{name:"",value:0}, …] }
#   CommandParser.parse("MapSys.place(layer_id=0, x=10, force_space=true)")
#   -> { is_value=false, name="MapSys.place", args=[{name:"layer_id",value:0}, …] }
#   CommandParser.parse("Test.int1")       -> { is_value=true, value=1 }
#
# 支持的数据类型（按判定优先级）:
#   - 数组字面量 : [a, b, c]（可嵌套）
#   - String     : **必须带引号**："a b c"；不带引号的一律当"取值"（见下）
#   - bool / int / float : true / false、5 / -10、3.5 / -0.25
#   - 取值表达式 : 其余全部按"值"求（路径、函数调用都算），**不需要 `$` 前缀**
#
# 取值链 / 路径 / 函数调用（一整条当表达式，末尾带 () 就是"调用后拿返回值"）:
#   Test.test_int                    读静态 var/const 的值
#   Test.test_int.value              读后取字典键 .value
#   Test.test_int[0].value[0].value  再取列表下标 [n] / 字典 .key（链式）
#   Test.test_func(Test.int1, -1)    调静态函数，参数逗号分隔，可递归写表达式
#   @123.config.content              实例成员（@ 后面是实例 ID）
#
# **一行 = 一个表达式，这就是全部语法**（不再区分"命令"与"取值"两套写法）:
#   类.静态方法(参数, 名字=值, …)   命令调用：位置参数按签名顺序；`名字=值` 可**跳过**可选参数（用签名的默认值）
#   其它（取值链 / 路径 / 字面量）   取值：末尾带 () 就"调完拿返回值"，不带 () 就取这个值本身
#   **取值链直接写**（`@self.control.text`、`Test.int1`；`$` 前缀可写可不写，效果一样）
#   **没有 flag 语法**——bool 参数直接写 `名字=true`。
#   **参数值只有一套编译**（_compile_value）：命令行参数、表达式参数、整行取值都走它 ⇒ 三处行为一致。
## 本类只做"命令字符串 → 名字 + 参数"的解析（含取值链），执行在 CmdSys。
## 解析结果带两级缓存（L1 热 LRU + L2 时间桶），命中就跳过编译，只重跑取值；
## 另外两张小表：路径（read/write）与拆行（split_lines）——key 都是配置里反复发的字符串。
## 被谁用：CmdSys.execute（唯一调用方）；清理由 CmdSys.clear_cache。

## class_name -> GDScript 懒缓存（找不到的类也缓存 null，避免反复扫全局类表）。
## 被谁用：_find_class_script（读/写）、clear_cache。
static var _class_scripts := {}   # class_name -> GDScript（懒缓存，供静态成员引用）

# ---- 两级解析缓存 ----
# L1：热缓存（LRU 双向链表），命中即移入表头；容量满时表尾降到 L2。
# L2：温缓存，用"时钟指针 + 时间桶"实现 O(1) 过期：
#   N 个桶排成环，每隔一个周期(秒)指针前进一格并清空该桶；
#   新项写入指针**下一个**桶（即"最新"桶），于是指针**当前**指向的桶就是最旧的一批。
#   桶数 N = ceil(TTL / 周期)，保证一项从写入到被清空恰好经历 TTL。
#   例：TTL=300s、周期=60s → 5 个桶，环形轮转，无需遍历扫描。
## 以下 L1/L2 各成员都被 _cache_* / _l1_* / _l2_* 系列读写，外部只经 clear_cache 清空。
static var _l1: Dictionary = {}      # key -> plan（LRU 冷热数据）
static var _l1_prev: Dictionary = {} # key -> 前驱 key（LRU 链表）
static var _l1_next: Dictionary = {} # key -> 后继 key（LRU 链表）
static var _l1_tail: String = ""     # LRU 表尾（最久未用）
static var _l1_head: String = ""     # LRU 表头（最近使用）
static var _l2_ring: Array[Dictionary] = []  # 时间桶数组：每个桶是一个 Dictionary
static var _l2_index: Dictionary = {} # key -> 桶下标（O(1) 查询/计数，size() 即 L2 条目数）
static var _l2_hand: int = 0         # 时钟指针：指向"最旧"的桶（下次轮转时清空）
static var _l2_last_tick: float = 0.0 # 上次轮转时刻(秒)

# ---- 另外两张小表（不参与 L1/L2 的淘汰，key 都是"配置/实例里反复出现的字符串"）----
# _path_cache：read / write 的路径 → { head:表达式计划, ops }（路径编译一次就够，不必每次重扫字符）
# _line_cache：整串指令 → 拆好的非空行（UI 事件是同一条串反复发，分裂结果直接复用）
# 统一用 _mini_cache_put 写：受 SysCfg.cache_command 开关控制，超过容量上限就整体清空。
static var _path_cache: Dictionary = {}
static var _line_cache: Dictionary = {}

## 把路径规范化：补上前导 `$`（路径参数是**字符串**，带不带 `$` 都行，等价）。
## 被谁用：read / write。
static func _normalize_path(path: String) -> String:
	var p: String = path.strip_edges()
	if not p.begins_with("$"):
		p = "$" + p
	return p


## 按路径**读**一个值（就是 `Utils.write` 那套路径语法的读版），返回 [ok, value]。
## 路径语法与取值式一致：`@123.config.content`、`Test.int1`、`a.b[0].c`、`UISys.get_ui("名字").config.content`。
## 编译结果进 _path_cache（与 write 共用同一张表）。
## 被谁用：Utils.swap（对调要先读出来）。
static func read(path: String) -> Array:
	var parts: Dictionary = _split_path(path)
	if parts.is_empty():
		return [false, null]
	return _run_expr(parts["head"])


## 按 `$` 路径**写入**一个值 —— 取值式的对称操作，同一套路径语法：
##   @123.config.content / a.b[0].c      实例成员、字典键、列表项（想写几层写几层）
##   Test.int1                           类脚本的 static 变量
##   UISys.get_ui("名字").config.content  带函数头的路径（先算函数当宿主，尾巴按 ops 写）
## **只有两个参数**（路径、值）：路径里已经带了宿主，不必再传一个"宿主"参数。
## 路径写成带引号的字符串（`Utils.write("@self.config.content", 值)`）：带不带前导 `$` 都行，等价。
## 成功返回 true；宿主/中间层取不到、最后一步不是可写的成员/下标时返回 false（不报错，调用方去提示）。
## 实现：路径编译成一个表达式计划后，把**最后一步**单独摘出来当赋值目标，前面那段交给 _run_expr 走
## （所以"kind → 宿主"的判断只有 _run_expr 一份，这里不再重复一遍）。
## 被谁用：Utils.write（指令 `Utils.write("<路径>", <值>)`）。
static func write(path: String, value: Variant) -> bool:
	var parts: Dictionary = _split_path(path)
	if parts.is_empty():
		return false
	var ops: Array = parts["ops"]
	if ops.is_empty():
		return false
	var steps: Array = ops.duplicate()
	var last: Dictionary = steps.pop_back()
	# 缓存的计划是共享的：副本上改 ops，别动表里那份
	@warning_ignore("unsafe_cast")
	var head: Dictionary = (parts["head"] as Dictionary).duplicate()
	head["ops"] = steps
	var walked: Array = _run_expr(head)      # 先走到"最后一步的宿主"上
	if not walked[0]:
		return false
	var host: Variant = walked[1]
	match str(last.get("op", "")):
		"field":
			var n: String = str(last["name"])
			if host is Dictionary:
				var d: Dictionary = host
				d[n] = value
				return true
			if host is Object:
				# 类脚本（GDScript）也是 Object：静态变量与实例成员都走这里
				var o: Object = host
				if n in o:
					o.set(n, value)
					return true
			return false
		"index":
			var idx: int = int(last["idx"])
			if host is Array:
				var arr: Array = host
				if idx >= 0 and idx < arr.size():
					arr[idx] = value
					return true
			return false
	return false


## 解析一行（多条由 CmdSys 按 '\v' 拆开再逐条调这里）。
## 取值行 ⇒ { is_value:true, value }；命令行 ⇒ { is_value:false, name, args:[{name, value}] }。
## 被谁用：CmdSys.execute。
static func parse(input: String) -> Dictionary:
	input = input.strip_edges()

	# 解析缓存：命中就跳过编译（取值/调用仍每次实时跑）。
	# 取值链被编译成"取值计划"缓存，只把定位过程固化，取值仍每次实时执行。
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


## 把一段文本当**一个值**求（与命令行参数、表达式参数、整行取值同一套编译：_compile_value）：
## 数字 / true / false / "字符串" / [数组] 都能算，其余按"取值表达式"试（算不出给 null）。
## 用途：编辑器那种"用户敲了一段字，要变成配置里的值"（如UI 编辑器改 config）。
## **求不出值返回 null，不报错也不打印**——调用方自己决定怎么兜（如按原样字符串）。
## 被谁用：CommandParser.parse_value（输入框里的字 → 配置值）。
static func parse_value(text: String) -> Variant:
	return _run_arg(_compile_value(text))

## 清空类脚本、两级解析缓存与两张小表（热重载 / 调试用）。
## 被谁用：CmdSys.clear_cache。
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
	_path_cache.clear()
	_line_cache.clear()


# ---------- 两张小表 ----------

## 小缓存的统一写入：`cache_command` 关着就不写；表满了先整体清空
## （这类 key 来自配置与实例，数量有限；宁可重算，也不让它无限涨）。
## 被谁用：_split_path（路径缓存）、split_lines（拆行缓存）。
static func _mini_cache_put(table: Dictionary, key: Variant, value: Variant) -> void:
	if not Sys.sysCfg.cache_command:
		return
	if table.size() >= Sys.sysCfg.cache_command_max:
		table.clear()
	table[key] = value


## 把路径拆成"宿主表达式 + 尾巴 ops"：整条路径就是一个表达式计划，把它的 ops 摘出来即可
## （write 要把最后一步单独拿出来赋值 ⇒ 只能走到倒数第二层；read 则整条跑，不走这儿）。
## 返回 {} = 路径非法（空路径 / 括号不配平）。带缓存（见 _path_cache）。
## 被谁用：read / write。
static func _split_path(path: String) -> Dictionary:
	var p: String = _normalize_path(path)
	if p == "$":
		return {}
	if _path_cache.has(p):
		return _path_cache[p]
	var plan: Dictionary = _compile_expr(p)
	if str(plan.get("kind", "")) == "invalid":
		return {}
	var parts: Dictionary = { "head": plan, "ops": plan.get("ops", []) }
	_mini_cache_put(_path_cache, p, parts)
	return parts


## 把整串指令按 '\v' 拆成"去空白后的非空行"（UI 事件反复发同一条串 ⇒ 拆一次就够）。
## 被谁用：CmdSys.execute。
static func split_lines(command_str: String) -> Array:
	if _line_cache.has(command_str):
		return _line_cache[command_str]
	var lines: Array = []
	for single in command_str.split("\v"):
		var line: String = single.strip_edges()
		if not line.is_empty():
			lines.append(line)
	_mini_cache_put(_line_cache, command_str, lines)
	return lines


# ---------- 缓存读写 ----------

## 取缓存：L1 命中就移到表头；L2 命中就回迁到 L1；都没有返回 null。
## 被谁用：parse。
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

## 写入 L1（满了先把表尾降级到 L2）；L1/L2 里已有就跳过。
## 被谁用：parse、_cache_get（L2 回迁）、_l1_touch。
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
## 被谁用：_cache_get。
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
## 被谁用：_cache_put。
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
## 被谁用：parse（每次解析前）。
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
## 被谁用：_l2_tick、_l2_insert（总量超限时强推指针）。
static func _l2_drop_bucket(idx: int) -> void:
	var bucket: Dictionary = _l2_ring[idx]
	_l2_ring[idx] = {}
	for key in bucket:
		_l2_index.erase(key)

# 写入 L2：进入"最新"桶（指针的下一格），保证存活时间≈TTL。
## 被谁用：_evict_l1_tail、_resize_ring。
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

## L2 里有没有这个 key。被谁用：_cache_put（避免重复写入）。
static func _l2_has(key: String) -> bool:
	return _l2_index.has(key)

## 清空 L2 全部桶与索引。被谁用：_l2_tick（TTL<=0 或轮转整圈）。
static func _l2_clear() -> void:
	for i in _l2_ring.size():
		_l2_ring[i] = {}
	_l2_index.clear()

# 重建桶数组：保留旧条目（并入新桶），避免配置变更丢失全部缓存。
## 被谁用：_l2_tick（桶数变化时）。
static func _resize_ring(count: int) -> void:
	var old := _l2_ring
	_l2_ring = []
	for i in count:
		_l2_ring.append({})
	_l2_index.clear()
	_l2_hand = 0
	if not old.is_empty():
		for bucket in old:
			for key in bucket:
				_l2_insert(key, bucket[key])

## 当前时间（秒，自引擎启动）。被谁用：_l2_tick。
static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# ---------- 编译 / 执行计划 ----------

## 把一行编译成"计划"（确定性的部分固化下来，取值留到 _run_plan 再跑）。
## **一行 = 一个表达式**，两种写法：
##   类.静态方法(参数, 名字=值, …)  → 命令调用（参数见 _compile_call_args）
##   其它（取值链 / 路径 / 字面量）  → 取值：末尾带 () 就"调完拿返回值"，不带 () 就取这个值本身
## **没有前缀**：末尾有没有 () 自己就说明了是"调用"还是"取值"。
## 被谁用：parse。
static func _compile(input: String) -> Dictionary:
	var call_: Dictionary = _split_call(input)
	if call_["ok"]:
		return { "is_value": false, "name": call_["name"], "args": _compile_call_args(call_["args"]) }
	return { "is_value": true, "arg": _compile_value(input), "src": input }


## 补上前导 `$`：一律当"表达式源码"交给 _compile_expr。
## 被谁用：_compile_value。
static func _as_expr(s: String) -> String:
	return s if s.begins_with("$") else "$" + s


## 拆"类.方法(参数)"：返回 { ok, name, args }。
## 只认"整行就是一个调用"：方法名是 `标识符.标识符`（命令只挂在这个命名上，见 CmdSys），
## 且**第一个 `(` 的配对 `)` 正好在行尾**——`UISys.get_ui("x").refresh("y")` 这种"尾巴还接着调用"
## 就不是命令，交给"取值"那条路（整行当表达式求值）。
## 被谁用：_compile。
static func _split_call(input: String) -> Dictionary:
	var s: String = input.strip_edges()
	if s.is_empty():
		return { "ok": false }
	var open: int = s.find("(")
	if open <= 0 or not s.ends_with(")"):
		return { "ok": false }
	if _match_paren(s, open) != s.length() - 1:
		return { "ok": false }
	var name: String = s.substr(0, open).strip_edges()
	if not _is_call_name(name):
		return { "ok": false }
	return { "ok": true, "name": name, "args": s.substr(open + 1, s.length() - open - 2) }


## 命令名形状：`标识符.标识符`（如 UIInteract.open、MapSys.place、Test.test_func）。
## 被谁用：_split_call。
static func _is_call_name(s: String) -> bool:
	var dot: int = s.find(".")
	if dot <= 0 or dot == s.length() - 1:
		return false
	for part in s.split("."):
		if not _is_ident(str(part)):
			return false
	return true


## 标识符：字母/下划线开头，后跟字母、数字、下划线。
## 被谁用：_is_call_name、_compile_call_args。
static func _is_ident(s: String) -> bool:
	if s.is_empty():
		return false
	var c0: String = s.substr(0, 1)
	if not _is_word_char(c0) or (c0 >= "0" and c0 <= "9"):
		return false
	for i in s.length():
		if not _is_word_char(s.substr(i, 1)):
			return false
	return true


## 标识符可用字符（字母 / 数字 / 下划线）。
## 被谁用：_is_ident。
static func _is_word_char(c: String) -> bool:
	if c == "_":
		return true
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


## 编译括号里的参数串：`值, 名字=值, …` ⇒ [{ name, plan }]（name 为空 = 位置参数）。
## 值可以是 `"字符串"`、`[…]` 数组字面量、`true/false`、数字、或取值表达式（self.xxx / Test.int1 …）。
## **跳过可选参数**靠"给名字"（`名字=值`，像 Python 的关键字参数）：没写的参数用签名里的默认值。
## 被谁用：_compile。
static func _compile_call_args(args_str: String) -> Array:
	var out: Array = []
	for part_raw: String in _split_top_level_args(args_str):
		var part: String = part_raw.strip_edges()
		if part.is_empty():
			continue
		var arg_name := ""
		var eq: int = _find_top_level_assign(part)
		if eq > 0:
			var maybe: String = part.substr(0, eq).strip_edges()
			if _is_ident(maybe):
				arg_name = maybe
				part = part.substr(eq + 1).strip_edges()
		out.append({ "name": arg_name, "plan": _compile_value(part) })
	return out


## 编译一个"值"——**只有这一套**：命令参数、表达式里的参数、整行取值都走它（三处行为必然一致）。
##   "字符串"        → 字符串（唯一写法）
##   [a, b]          → 数组字面量（元素递归）
##   true / false / 12 / 1.5 → 布尔 / 整数 / 小数
##   其它（self.xxx、QName.x、Test.int1、UISys.get_ui("x").refresh("y")）→ 当表达式求值
## 计划用 dict 表示：{ lit:true, value } / { lit:true, array:[子计划] } / { lit:false, expr }。
## 被谁用：_compile（整行取值）、_compile_call_args（命令参数）、_compile_expr_args（表达式参数）、
##         以及数组元素递归调它自己。
## 找**顶层**的冒号（不在引号 / 括号里）——字典字面量 `"键": 值` 的分隔点。
## 被谁用：_compile_value（字典分支）。
static func _find_top_level_colon(s: String) -> int:
	var depth: int = 0
	var quote: String = ""
	var i: int = 0
	while i < s.length():
		var c: String = s[i]
		if quote != "":
			if c == quote:
				quote = ""
		elif c == "\"" or c == "'":
			quote = c
		elif c == "[" or c == "{" or c == "(":
			depth += 1
		elif c == "]" or c == "}" or c == ")":
			depth -= 1
		elif c == ":" and depth == 0:
			return i
		i += 1
	return -1


static func _compile_value(raw: String) -> Dictionary:
	var s: String = raw.strip_edges()
	if s.begins_with("[") and s.ends_with("]"):
		var items: Array = []
		for item_raw: String in _split_top_level_args(s.substr(1, s.length() - 2)):
			var item: String = item_raw.strip_edges()
			if not item.is_empty():
				items.append(_compile_value(item))
		return { "lit": true, "array": items }
	if s.begins_with("{") and s.ends_with("}"):
		# **字典字面量**：`{"键": 值, …}`——键 / 值各自还能是字面量、数组、字典或取值式（递归编）。
		# 于是"打开时传一份配置片段"能直接写出来：`config={"content_cmd": "@UI/MiniHUD/Info.config"}`。
		var keys: Array = []
		var vals: Array = []
		for pair_raw: String in _split_top_level_args(s.substr(1, s.length() - 2)):
			var pair: String = pair_raw.strip_edges()
			if pair.is_empty():
				continue
			var colon: int = _find_top_level_colon(pair)
			if colon < 0:
				break                     # 有一对没有冒号：整条退回表达式（判 invalid，不静默吃掉）
			keys.append(_compile_value(pair.substr(0, colon)))
			vals.append(_compile_value(pair.substr(colon + 1)))
		if keys.size() == vals.size():
			return { "lit": true, "dict_keys": keys, "dict_values": vals }
		return { "lit": false, "expr": _compile_expr(_as_expr(s)) }
	if s.length() >= 2 and s.begins_with("\"") and s.ends_with("\""):
		return { "lit": true, "value": s.substr(1, s.length() - 2) }
	var lit: Variant = _convert_literal(s)
	if lit != null:
		return { "lit": true, "value": lit }
	return { "lit": false, "expr": _compile_expr(_as_expr(s)) }


## 执行计划，得到 parse() 的结果：取值行 ⇒ { is_value:true, value }；
## 命令行 ⇒ { is_value:false, name, args:[{name, value}] }。
## 被谁用：parse（缓存命中与未命中都走它）。
static func _run_plan(plan: Dictionary) -> Dictionary:
	if plan.get("is_value", false):
		var got: Variant = _run_arg(plan["arg"])
		if got is Callable:
			# 忘写 ()：整行是个"方法名"，取到的是函数本身而不是调用结果
			push_warning("CommandParser: 「%s」没写 ()，取到的是函数本身（要调用请写成 名字(参数)）" % str(plan.get("src", "")))
		return { "is_value": true, "name": "", "value": got }
	var args: Array = []
	for a_raw in plan["args"]:
		var a: Dictionary = a_raw
		args.append({ "name": a["name"], "value": _run_arg(a["plan"]) })
	return { "is_value": false, "name": plan["name"], "args": args }


## 执行一个参数计划（数组字面量按元素递归）。取不到值时给 null（命令行参数一直如此）。
## 被谁用：_run_plan、_run_arg_plans、_run_arg（数组元素递归）。
static func _run_arg(p: Variant) -> Variant:
	@warning_ignore("UNSAFE_METHOD_ACCESS")
	if p is Dictionary and p.has("lit"):
		var d: Dictionary = p
		if not d["lit"]:
			@warning_ignore("unsafe_cast")
			var ev: Array = _run_expr(d["expr"] as Dictionary)
			return ev[1] if ev[0] else null
		if d.has("array"):
			var out: Array = []
			for item in d["array"]:
				out.append(_run_arg(item))
			return out
		if d.has("dict_keys"):
			var dict: Dictionary = {}
			var ks: Array = d["dict_keys"]
			var vs: Array = d["dict_values"]
			for i in ks.size():
				dict[_run_arg(ks[i])] = _run_arg(vs[i])
			return dict
		return d["value"]
	return p


## 跑一组参数计划，返回 [ok, values]。
## 与 _run_arg 的差别：**表达式**参数取不到值就整组失败（"参数没算出来"不该当 null 传进去）；
## 字面量 / 数组不受影响。
## 被谁用：_run_expr（函数参数）、_run_ops（方法参数）——两处共用，不再各写一遍。
static func _run_arg_plans(plans: Array) -> Array:
	var values: Array = []
	for p in plans:
		@warning_ignore("unsafe_cast")
		if p is Dictionary and not (p as Dictionary).get("lit", true):
			@warning_ignore("unsafe_cast")
			var ev: Array = _run_expr((p as Dictionary)["expr"] as Dictionary)
			if not ev[0]:
				return [false, []]
			values.append(ev[1])
		else:
			values.append(_run_arg(p))
	return [true, values]


## 找顶层（不在引号 / 括号里）的 `=`，且不是 `==` / `!=` / `>=` / `<=` 的一部分；没有返回 -1。
## 被谁用：_compile_call_args（判 `名字=值`）。
static func _find_top_level_assign(s: String) -> int:
	var depth := 0
	var in_quote := false
	for i in s.length():
		var c: String = s.substr(i, 1)
		if c == "\"":
			in_quote = not in_quote
			continue
		if in_quote:
			continue
		if c == "(" or c == "[":
			depth += 1
			continue
		if c == ")" or c == "]":
			depth -= 1
			continue
		if c == "=" and depth == 0:
			var prev: String = s.substr(i - 1, 1) if i > 0 else ""
			var next: String = s.substr(i + 1, 1) if i + 1 < s.length() else ""
			if next == "=" or prev == "=" or prev == "!" or prev == ">" or prev == "<":
				continue
			return i
	return -1


# ---------- $ 表达式的编译 / 执行 ----------
# 计划用 dict 表示，把"定位"固化下来，运行时只做必需的最后一步取值：
#   { "kind": "instance", "ref": String, "ops": [...] }          @引用.<ops>（引用 = 实例 ID 或注册名）
#   { "kind": "member", "owner": String(类名), "ops": [...] }     $类.<成员链>
#   { "kind": "func", "callable": Callable, "args": [<plan>...], "ops": [...] } $类.函数(...) 后面接着的成员链
#   { "kind": "literal", "value": Variant }                      字面量（函数/方法参数）
# ops 每项：
#   { "op": "field", "name": String }            .名称
#   { "op": "index", "idx": int }                [n]
#   { "op": "method", "name": String, "args": [<plan>...] }  .名称(...)

## 编译一个以 "$" 开头的表达式。
## 被谁用：_compile_value（值 / 参数 / 整行取值都经它）、_split_path（read / write 的路径）。
static func _compile_expr(s: String) -> Dictionary:
	var body := s.substr(1)   # 去掉前导 $
	# 实例 / 命名对象访问：@引用.成员 或 @引用.方法(...)；引用 = 实例 ID 或**注册名**（见 _chain_ref）
	if body.begins_with("@"):
		if body == "@event":
			return { "kind": "event" }        # 当前事件名（字符串）；由 UIBase.on_event 设好上下文
		var inst_expr := body.substr(1)
		var ref_res := _chain_ref(inst_expr)
		if not ref_res[0]:
			return { "kind": "invalid" }
		return { "kind": "instance", "ref": ref_res[1], "ops": _compile_ops(_chain_rest(inst_expr)) }
	# 找第一个 "(" 判断是否为函数调用（没有 = 纯成员链）
	var paren := body.find("(")
	if paren < 0:
		# 纯读值：成员链。定位"宿主"到第一个 '.' 之前（类名或静态成员），之后交给 ops。
		var dot := body.find(".")
		var head := body if dot < 0 else body.substr(0, dot)
		var rest := "" if dot < 0 else body.substr(dot)
		return { "kind": "member", "owner": head, "ops": _compile_ops(rest) }
	# 函数调用：定位静态函数（Callable 固化），参数编译成子计划
	var close := _match_paren(body, paren)
	if close < 0:
		return { "kind": "invalid" }   # 括号不配平：整条作废（不去猜尾巴从哪开始）
	var func_expr := body.substr(0, paren)
	var resolved_func := _try_resolve_method(func_expr)
	if not resolved_func[0]:
		return { "kind": "invalid" }
	# 函数尾巴还能继续接成员链（`UISys.get_ui("x").config.content`、`self.get_x().refresh()`）：
	# 编进 ops，执行时对函数结果继续走。
	return {
		"kind": "func",
		"callable": resolved_func[1],
		"args": _compile_expr_args(body.substr(paren + 1, close - paren - 1)),
		"ops": _compile_ops(body.substr(close + 1)),
	}

## 执行已编译的表达式计划，返回 [ok, value]。
## 被谁用：_run_arg / _run_arg_plans、_run_ops（方法参数）、read（路径）、_run_expr（递归）。
static func _run_expr(plan: Dictionary) -> Array:
	match plan.get("kind", ""):
		"event":
			return [true, event_name]
		"instance":
			var obj: Object = _instance_of(str(plan.get("ref", "")))
			if obj == null:
				return [false, null]
			return _run_ops(obj, plan["ops"])
		"member":
			return _run_member(plan["owner"], plan["ops"])
		"func":
			var callable: Callable = plan["callable"]
			var ran: Array = _run_arg_plans(plan["args"])
			if not ran[0]:
				return [false, null]
			var result: Variant = callable.callv(ran[1])
			@warning_ignore("unsafe_method_access")
			var tail: Array = plan.get("ops", [])       # 函数后面接的成员链（可能为空）
			if tail.is_empty():
				return [true, result]
			return _run_ops(result, tail)
		_:
			return [false, null]   # invalid / 未知 kind

## 当前正在派发事件的元素与事件名：`@self` / `@host` / `@event` 认它们。
## 由 UIBase.on_event 在发送前设好——每次派发是**同步**的（send_cmd 跑完就回来），静态变量够用。
## 不在这条链上的指令（测试、定时器）里别写 `@self`：那时它是上一次派发留下的 / 空的。
static var event_ui: Object = null
static var event_name: String = ""


## 解析 `@引用` 得到那个实例。引用有四种：
##   `self` / `host`  —— 当前派发事件的元素 / 它的管理对象（见 event_ui、UIBase._find_host）；
##   实例 ID（数字，可带负号）—— 没登记名字的对象；判数字看首字符（64 位 ID 用 is_valid_int 会误判）；
##   注册名           —— 其余一律按注册名查（`UI/MiniHUD/Info` 这种，见 RegSys）。
## 被谁用：_run_expr（instance 分支）。
static func _instance_of(ref: String) -> Object:
	if ref.is_empty():
		return null
	if ref == "self":
		return event_ui
	if ref == "host":
		var ui: UIBase = event_ui as UIBase
		return ui._find_host() if ui != null else null
	if ref[0] == "-" or (ref[0] >= "0" and ref[0] <= "9"):
		return instance_from_id(int(ref))
	return RegSys.get_(ref)


## 拆分 "@引用.<...>" 得到 <...> 部分（去掉引用本身）。
## 被谁用：_compile_expr（instance 分支）。
static func _chain_rest(inst_expr: String) -> String:
	var i := 0
	while i < inst_expr.length() and inst_expr[i] != "." and inst_expr[i] != "[" and inst_expr[i] != "(":
		i += 1
	return inst_expr.substr(i)

## 取 "@引用.<...>" 里那段引用（第一个 `.` / `[` / `(` 之前的内容），返回 [ok, ref]。
## **引用可以是实例 ID，也可以是注册名**（如 `@UI/MiniHUD/Menu`，见 RegSys）——交给 _instance_of 去分辨：
## 数字 = ID，其余 = 注册名（名字里常有 `/`，所以这里只把 `.` `[` `(` 当结束符）。
## 不能用 0 / 空串当"无效"哨兵（合法 ID 本身就可能为负）⇒ 用 [ok, ref] 返回。
## 被谁用：_compile_expr（instance 分支）。
static func _chain_ref(inst_expr: String) -> Array:
	var i := 0
	while i < inst_expr.length():
		var c := inst_expr[i]
		if c == "." or c == "[" or c == "(":
			break
		i += 1
	var ref: String = inst_expr.substr(0, i).strip_edges()
	if ref.is_empty() or ref == "-":
		return [false, ""]
	return [true, ref]

## 编译成员链（<...> 部分）为 ops 数组。
## 被谁用：_compile_expr（三种 kind 都编尾巴 ops）。
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
				ops.append({ "op": "method", "name": seg, "args": _compile_expr_args(args_str) })
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

## 编译表达式里的参数串：`值, 值, …`（纯位置，与 GDScript 一致，没有 `名字=值`）。
## **每个值都交给 _compile_value**——与命令参数、整行取值是同一套编译，
## 于是 `true/false`、数组字面量 `[…]`、字符串、取值链在这三处的行为必然一致（计划形状也相同）。
## 被谁用：_compile_expr（函数参数）、_compile_ops（方法参数）。
static func _compile_expr_args(args_str: String) -> Array:
	var plans: Array = []
	for ap_raw: String in _split_top_level_args(args_str):
		var ap: String = ap_raw.strip_edges()
		if not ap.is_empty():
			plans.append(_compile_value(ap))
	return plans

## 对已取到的宿主值执行成员链 ops。
## 支持宿主是 GDScript（静态成员/常量）、Object（实例属性/方法）、Dictionary（键）。
## 被谁用：_run_expr（instance / func 尾巴）。
static func _run_ops(v: Variant, ops: Array) -> Array:
	for op in ops:
		match op["op"]:
			"field":
				if v is GDScript:
					# 类脚本：先当静态属性读，读不到再查常量表（const 不在属性列表里），
					# 再读不到就当方法名给个 Callable（与 GDScript 的 `类.方法` 一致）
					var s: GDScript = v
					if op["name"] in s:
						v = s.get(op["name"])
					else:
						var consts: Dictionary = s.get_script_constant_map()
						if consts.has(op["name"]):
							v = consts[op["name"]]
						elif s.has_method(op["name"]):
							v = Callable(s, op["name"])
						else:
							return [false, null]
				elif v is Object:
					var obj: Object = v
					if op["name"] in obj:
						v = obj.get(op["name"])
					elif obj.has_method(op["name"]):
						v = Callable(obj, op["name"])   # 方法名读成可调用值（与 GDScript 的 obj.method 一致）
					else:
						return [false, null]
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
				var ran: Array = _run_arg_plans(op["args"])
				if not ran[0]:
					return [false, null]
				v = obj2.callv(op["name"], ran[1])
			_:
				return [false, null]
	return [true, v]

## 执行 "$类.<成员链>"：取类脚本作为静态宿主，再走 ops。
## 被谁用：_run_expr（member 分支）。
static func _run_member(owner: String, ops: Array) -> Array:
	# $ 表达式的宿主只支持类名（$类名.xxx），取类脚本后走 ops
	var script := _find_class_script(owner)
	if script == null:
		return [false, null]
	return _run_ops(script, ops)


# 找到从 start（指向 '('）开始配对的 ')' 下标；未匹配返回 -1。
## 被谁用：_compile_ops（方法参数）。
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


# 把括号内参数字符串按逗号拆分成顶层项（忽略嵌套括号/引号内的逗号）。
## 被谁用：_compile_call_args、_compile_expr_args、_compile_value（数组元素）。
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
		elif c == "(" or c == "[" or c == "{":
			depth += 1
			cur += c
		elif c == ")" or c == "]" or c == "}":
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


# 普通字面量：bool / int / float。**不是字面量返回 null**（调用方接着当"表达式"处理）。
## 被谁用：_compile_value。
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
	return null


## 判定是否为十进制整数（支持前导 +/-，不限 32 位）。
## 被谁用：_convert_literal。
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
## 被谁用：_compile_expr（函数调用分支）。
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
## 被谁用：_run_member、_try_resolve_method。
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
