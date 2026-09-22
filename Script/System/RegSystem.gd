class_name RegSys
extends BaseClass
## 注册名系统：**注册名 ↔ 实例** 的映射（"这东西叫什么"的统一出处）。
##
## 为什么要有它：
##   · 配置与指令里要能"按名字指到某个东西"（`@UI/MiniHUD`、`config["host"] = "UI/MiniHUD/Menu"`）
##     ⇒ **名字 → 实例**；
##   · 反过来也要能问"这东西叫什么"（显示给人看、拼层级名、构造 `@注册名`）⇒ **实例 → 名字**。
##   两张表一起维护，就不会出现"一边认得、一边认不得"。
##
## **只管名字，不管层级怎么长**：层级名一律 `join(父, 名字)`（`父名/子名`）——UI 树用它，
## 以后别的树（角色 / 地图层…）照这条来即可，于是"名字长什么样"只有本类一处。
##
## **只用注册名**：名字可读、能存盘、跨运行也对得上；实例 ID 每次运行都变、写盘也存不住，本项目不用它寻址。
## 于是"能不能指到"取决于"有没有登记名字"（角色由 Character._init 登记、UI 由 UISys 登记）——没登记的东西指不到，
## 这一点由指令解析器如实报出（见 CommandParser._instance_of），本类不掺和。
##
## 成员全是静态的：`RegSys.get_(名字)` / `RegSys.name_of(实例)` / `RegSys.join(父, 名字)`。

## 注册名 → 实例。
static var _to_obj: Dictionary = {}
## 实例 → 注册名（键就是实例本身，于是"同一个实例只有一个名字"天然成立）。
static var _to_name: Dictionary = {}
## **占名计数**：基名 -> 已经发出去几个（`Char/人类` 发过 3 个就记 3）。
## 给"重名自动让路"算下一个号用（见 _claim）：一次查表，**不去遍历所有登记名**——
## 登记对象只会越来越多，遍历会随游戏时长越来越慢；查表则与登记总量无关。
static var _used_count: Dictionary = {}


## 登记 / 改名：把实例登记成某个注册名（同一个实例再登记会先摘掉旧名，所以**改名就是再登记一次**）。
## **返回真正用上的登记名**：重名让路的场合名字可能被改号（`Char/人类` → `Char/人类_2`），
## 想要那个名字就得接住返回值（`var reg_name := RegSys.register(self, 名字, true)`）。
## `dedup`（重名让路）：
##   · **false（默认）**：同名是**覆盖**（后来者占掉这个名字，并警告一声）。给"同一个东西改名再登记"
##     与"同一个 UI 开两次要复用同一份"的场合（`UI/MiniHUD` 只能有一个，见 UISys）；
##   · **true**：同名**自动加后缀**（号从 _used_count 取，见 _claim）。给"同类东西可以有很多个"的
##     场合（角色就是：一堆 `Char/人类`），于是每个实例都有自己的名字。
## 被谁用：Character._init（dedup=true）、UISys._register_tree（默认）。
static func register(obj: Object, want: String, dedup: bool = false) -> String:
	if obj == null or want == "":
		return ""
	unregister(obj)                                 # 同一个实例换名字：先摘掉旧名
	var reg_name: String = _claim(want) if dedup else want
	if not dedup and _to_obj.has(reg_name):
		push_warning("RegSys: 注册名「%s」被重复使用（后来的实例覆盖它）" % reg_name)
	_to_obj[reg_name] = obj
	_to_name[obj] = reg_name
	return reg_name


## 在 `base` 名下**占一个号**：没人用过就给 `base`，用过就顺号给 `base_2`、`base_3`…
## 号从 `_used_count` 取（不必去数登记表里有多少个同类名字），登记表只用来兜底：
## 万一这个名字被别人手写登记过（没走这条路的），接着往后找。
## **号只增不减（不回收）**：名字一旦发出去就一直是"那个东西的名字"——回收的话后来者会顶着旧名字，
## 而消息节点 ID 是按名字拼的，顶名就等于串消息（见 MessageHub._format_*）。
## 被谁用：register（dedup = true）。
static func _claim(base: String) -> String:
	var n: int = int(_used_count.get(base, 0))
	var out: String = base if n == 0 else "%s_%d" % [base, n + 1]
	while _to_obj.has(out):
		n += 1
		out = "%s_%d" % [base, n + 1]
	_used_count[base] = n + 1
	return out


## 摘掉一个实例的注册（不在表里就什么都不做）。
## **动态删掉一个实例之前要先摘**（见 UIBase.clear_children）：表里存着实例本身，
## 摘掉才不会留下一个指向"已经没了的东西"的名字。
static func unregister(obj: Object) -> void:
	if obj == null or not is_instance_valid(obj):
		return
	if not _to_name.has(obj):
		return
	_to_obj.erase(str(_to_name[obj]))
	_to_name.erase(obj)


## 按注册名取实例（没登记 / 实例已经没了给 null）。
static func get_(reg_name: String) -> Object:
	var obj: Object = _to_obj.get(reg_name)
	return obj if is_instance_valid(obj) else null


## 实例 → 注册名（没登记给空串）。
static func name_of(obj: Object) -> String:
	if obj == null or not is_instance_valid(obj):
		return ""
	return str(_to_name.get(obj, ""))


## 这个名字登记过没有。
static func has(reg_name: String) -> bool:
	return get_(reg_name) != null


## 拼层级名：`父的注册名/名字`；父没登记（null 或没名字）就只用名字本身。
## 被谁用：UISys.register_child / _register_tree（UI 树的登记名就只有这一条规则）。
static func join(parent: Object, name_: String) -> String:
	var parent_name: String = name_of(parent)
	return name_ if parent_name == "" else parent_name + "/" + name_


## 所有已登记的名字（给"要遍历一遍"的兜底用，如 UISys.refresh_all）。
static func names() -> Array:
	return _to_obj.keys()


## **对着一份"已占清单"去重**：`want` 没在里面就原样还它，在就加后缀 `_2`、`_3`…
## 与 register 的 dedup 是**同一条后缀规则**，区别只在"已占"从哪来：
##   · 这里由调用方给清单（`taken`）——UI 建树时父元素**自己还没登记**，不能查登记表，
##     只能按"已有的兄弟名"判（见 UIBase._unique_child_name）；
##   · register 的 dedup 走 `_claim`：按**计数表**算号，对象可能成千上万也不遍历（角色走那条）。
## 被谁用：UIBase._unique_child_name。
static func unique(want: String, taken: Array) -> String:
	var base: String = want if want != "" else "Unnamed"
	if not taken.has(base):
		return base
	var i: int = 2
	while taken.has("%s_%d" % [base, i]):
		i += 1
	return "%s_%d" % [base, i]


## 清空三张表（热重载 / 调试用；占名计数也一起清，否则名字会从上次的号接着往下发）。
static func clear() -> void:
	_to_obj.clear()
	_to_name.clear()
	_used_count.clear()
