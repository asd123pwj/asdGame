class_name AutoSys
extends BaseClass
## 状态驱动执行器（设计见 Script/Auto/Auto.md）。
## 一句话：**"某角色某状态满足期间，每帧跑一个函数"**。
## 一条登记 = `[角色, 状态名, Callable]`；每帧 _process() 过一遍：
##   状态还满足 → 调这个 Callable；状态不满足（松手/结束）→ 直接删掉这条登记。
##
## 为什么需要：有些交互要"按住期间一直做"，但指针会离开元素——
## 等比缩放最典型：手柄必然被指针甩在身后，按 hover 派发的事件中途就断了。
## 挂在状态上就没这问题：状态满足与"指针在哪"无关，也不用写"松开"那一半。
##
## **登记方是代码，不是配置**：指令只写在配置里（指令是字符串，散在代码里以后不好统一改），
## 所以 UI 侧的做法是——配置里那条指令只调 `UIInteract.drag` / `UIInteract.rescale`（登记入口），
## 由它们把"每帧要跑的函数"用 `Callable.bind` 交到这里。
## 写法见那两对函数：Script/UI/UIInteract_Drag.gd（drag + dragging）、
## Script/UI/UIInteract_Rescale.gd（rescale + rescaling）。
##
## 被谁用：UIInteract.drag / UIInteract.rescale（登记）；每帧由 `Sys._process` 直接调（见下）。

## 登记项：`[Character, 状态名, Callable]`。同一组可以并存多条（各自独立判存亡）。
static var autos: Array = []


## 登记"状态满足期间每帧跑 callback，**状态一旦不满足就销毁这条登记**"：
## 同一个 角色+状态名+回调 只登记一次（重复调用无副作用）。
## 名字强调后半个过程：不是"满足时都跑"，而是"跑，直到不满足"——不满足即销毁。
## 被谁用：UIInteract.drag / UIInteract.rescale（这两个是配置里的登记入口）。
static func run_until_unsatisfied(char_: Character, status_name: String, callback: Callable) -> void:
	if char_ == null or status_name.is_empty() or callback.is_null():
		return
	if _index_of(char_, status_name, callback) >= 0:
		return
	autos.append([char_, status_name, callback])


## 手动注销该角色该状态名下的全部登记。一般用不到（状态不满足时 _process 会自己删）。
## 被谁用：想提前收尾的调用方。
static func stop(char_: Character, status_name: String) -> void:
	for i in range(autos.size() - 1, -1, -1):
		var entry: Array = autos[i]
		if entry[0] == char_ and entry[1] == status_name:
			autos.remove_at(i)


## 每帧过一遍：状态不满足就删，满足就调它的回调。
## 用副本遍历：回调里可能又登记/注销（例如开关换来换去）。
## 状态没装（名字写错）按不满足处理，顺手删掉，免得一直空转。
## 被谁用：Sys._process（排在 InputSys / TimeSys 之后，所以本帧的 mouse_delta 已经能用了）。
static func _process(_delta: float) -> void:
	for entry: Array in autos.duplicate():
		var char_: Character = entry[0]
		if char_ == null or not char_.statuses.check_exist(entry[1]) \
				or not char_.statuses.check_satisfied(entry[1]):
			stop(char_, entry[1])
			continue
		var callback: Callable = entry[2]
		callback.call()


## 登记项在列表里的下标（-1 = 没登记过）。
## 不用 Array.erase / has：**Callable 的 == 不比较绑定参数**（实测 `erase(bind(x))` 摘不掉），
## 这里按"同一个函数 + 同一个对象 + 同一组绑定参数"自己比。
## 被谁用：run_until_unsatisfied。
static func _index_of(char_: Character, status_name: String, callback: Callable) -> int:
	for i in autos.size():
		var entry: Array = autos[i]
		if entry[0] != char_ or entry[1] != status_name:
			continue
		var item: Callable = entry[2]
		if item.get_method() == callback.get_method() \
				and item.get_object() == callback.get_object() \
				and item.get_bound_arguments() == callback.get_bound_arguments():
			return i
	return -1
