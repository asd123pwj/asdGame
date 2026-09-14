class_name Statuses
extends BaseClass
## 某角色的状态集合（增删查 + 查询满足/最近消息）。
## 每个状态的监听与判定都在 StatusPreset 里；本类只是"这个角色装了哪些状态"的门面。
## 被谁用：Character.statuses；交互/技能/快捷的依赖状态判定、指令。

## 所属角色。被谁用：各查询与增删（状态按角色记 satisfied）。
var me: Character
## 已装状态：预设名 -> 预设。被谁用：check_satisfied / get_latest_message / remove。
var statuses: Dictionary[String, StatusPreset] = {}

## 装配：记下所属角色并装入原型声明的状态。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, status_name: Array[String]) -> void:
    self.me = me
    add_statuses(status_name)


## 收尾：让每个状态做一次"首次判定"（装配前就已满足的条件要立即生效）。
## 被谁用：Character.init_done。
func char_init_done() -> void:
    for status: StatusPreset in statuses.values():
        status.char_init_done(me)

## 某状态当前是否满足（没装该状态返回 false）。
## 被谁用：SkillPreset.listen（判当前是否该入队）、条件判定、指令。
func check_satisfied(status_name: String) -> bool:
    if not check_exist(status_name):
        return false
    return statuses[status_name].satisfied[me]


## 取某状态最近一次判定的消息（常用来拿 target）。
## 被谁用：InteractionPreset.listen（取交互对象）、状态定向判定。
func get_latest_message(status_name: String) -> Variant:
    if not check_exist(status_name):
        return null
    return statuses[status_name].get_latest_message(me)

""" ---------- Listeners ---------- """
## 批量加。被谁用：_init、运行时批量加。
func add_statuses(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(add_status(name))
    return codes

## 加一个状态：登记 → 让预设开始监听它的各类条件 → 广播。重复加返回 NOT_MODIFIED。
## 被谁用：add_statuses、指令。
func add_status(status_name: String) -> Enums.Code:
    if statuses.has(status_name):
        return Enums.Code.NOT_MODIFIED
    var status: StatusPreset = StatusPreset.get_(status_name)
    statuses[status_name] = status
    status.listen(me)
    Msg.send_status_add(me, status_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除。
func remove_statuses(status_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in status_name:
        codes.append(remove_status(name))
    return codes

## 移除一个状态：退订监听 → 从字典删 → 广播。
## 被谁用：remove_statuses、指令。
func remove_status(status_name: String) -> Enums.Code:
    if not statuses.has(status_name):
        return Enums.Code.NOT_MODIFIED
    statuses[status_name].unlisten(me)
    statuses.erase(status_name)
    Msg.send_status_remove(me, status_name)
    return Enums.Code.OK

## 有没有装某个状态。被谁用：check_satisfied / get_latest_message、条件判定。
func check_exist(status_name: String) -> bool:
    return statuses.has(status_name)
