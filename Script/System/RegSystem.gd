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
## **不碰实例 ID**：ID 是运行期的东西（每次运行都不一样、写盘也存不住），要"指到某个实例"就用注册名。
## 只有 ID 的场合（如还没起名字的角色、老的 `@数字` 写法）由指令解析器自己兜底
## （见 CommandParser._instance_of），本类不掺和。
##
## 成员全是静态的：`RegSys.get_(名字)` / `RegSys.name_of(实例)` / `RegSys.join(父, 名字)`。

## 注册名 → 实例。
static var _to_obj: Dictionary = {}
## 实例 → 注册名（键就是实例本身，于是"同一个实例只有一个名字"天然成立）。
static var _to_name: Dictionary = {}


## 登记 / 改名：把实例登记成某个注册名（同一个实例再登记会先摘掉旧名，所以**改名就是再登记一次**）。
## 注册名**全项目唯一**：撞名时后来者覆盖并警告一声（UI 的"同一挂载点下不要重名"就是这么来的）。
## 被谁用：UISys._register_tree（整棵 UI 树递归登记）。
static func register(obj: Object, reg_name: String) -> void:
	if obj == null or reg_name == "":
		return
	unregister(obj)                                 # 同一个实例换名字：先摘掉旧名
	if _to_obj.has(reg_name):
		push_warning("RegSys: 注册名「%s」被重复使用（后来的实例覆盖它）" % reg_name)
	_to_obj[reg_name] = obj
	_to_name[obj] = reg_name


## 摘掉一个实例的注册（不在表里就什么都不做）。
## **动态删掉一个实例之前要先摘**（见 UI_Editor._remove_tree）：表里存着实例本身，
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


## 清空两张表（热重载 / 调试用）。
static func clear() -> void:
	_to_obj.clear()
	_to_name.clear()
