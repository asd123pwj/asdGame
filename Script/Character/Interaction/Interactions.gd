class_name Interactions
extends BaseClass
## 某角色的交互集合（增删查）。交互的实现与触发条件都在 InteractionPreset 里。
## 被谁用：Character.interactions（角色装配时建）；指令里按名增删。

## 所属角色。被谁用：add/remove（传给预设去 listen/unlisten）。
var me: Character
## 已装交互：预设名 -> 预设。被谁用：check_exist、remove。
var interactions: Dictionary[String, InteractionPreset] = {}

## 每个交互"最后一次发生"的流水：交互名 -> `{动作: {"clock": 现实时间, "text": 游戏时间}}`，
## 另有 `"act_count"`（触发次数）。**加装 / 移除 / 触发三个动作都记**。
## **为什么要记**：交互触发只持续一帧（见 InteractionPreset.listen），跑过去就没了——记一笔才看得出
## "刚才到底触发没触发 / 什么时候加的 / 什么时候被移除的"（角色交互一览就照它显示"最近执行"）。
## **移除也留档**：交互从 interactions 里删了，这一笔仍留着（不然"刚删了什么"完全查不到）。
## 被谁用：add_interaction / remove_interaction（自己记）、InteractionPreset.listen 的触发（act）、
##         UI_Interaction（读它显示）。
var history: Dictionary[String, Dictionary] = {}


## 记一笔流水（动作：`add` / `remove` / `act`）。时间取**当下**，两份都存：
##   · `clock` = **现实墙上时钟**（`14:03:21.437`）——"具体时间"，毫秒级才分得开连续触发；
##   · `text`  = **游戏时间**（`元年正月初一 子时`，见 TimeFormat.now_text）——游戏内的"几时"。
## （不记 `TimeSys.elapse`：那是个开机以来的秒数，只增不减，看着没用。）
## 触发另计次数——"一帧事件"来过几次全看这个。
## **先记再广播**：接收方（交互一览）要在收到消息时读到刚记下的这一笔，才算得对时间。
## 被谁用：add_interaction / remove_interaction / InteractionPreset.listen 的触发函数。
func record(interaction_name: String, action: String) -> void:
    var rec: Dictionary = history.get(interaction_name, {})
    rec[action] = {"clock": _clock_text(), "text": TimeFormat.now_text()}
    if action == "act":
        rec["act_count"] = int(rec.get("act_count", 0)) + 1
    history[interaction_name] = rec


## 现实墙上时钟的"当下"文本：`14:03:21.437`（本地时间，毫秒是补上的——引擎只给到秒，
## 而交互一秒可能触发好几次，只到秒就分不出先后）。
## 被谁用：record。
static func _clock_text() -> String:
    return "%s.%03d" % [Time.get_time_string_from_system(), Time.get_ticks_msec() % 1000]

## 装配：记下所属角色并装入原型声明的交互。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, interactions_name: Array[String]) -> void:
    self.me = me
    add_interactions(interactions_name)

## 批量加。被谁用：_init、运行时批量加。
func add_interactions(interactions_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in interactions_name:
        codes.append(add_interaction(name))
    return codes

## 加一个交互：登记 → 让预设开始监听依赖状态 → 广播。重复加返回 NOT_MODIFIED。
## 被谁用：add_interactions、指令。
func add_interaction(interaction_name: String) -> Enums.Code:
    if interaction_name in interactions:
        return Enums.Code.NOT_MODIFIED
    var interaction = InteractionPreset.get_(interaction_name)
    interactions[interaction_name] = interaction
    interaction.listen(me)
    record(interaction_name, "add")
    Msg.send_interaction_add(me, interaction_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除。
func remove_interactions(interactions_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in interactions_name:
        codes.append(remove_interaction(name))
    return codes

## 移除一个交互：退订它的监听 → 从字典删 → 广播。
## 被谁用：remove_interactions、指令。
func remove_interaction(interaction_name: String) -> Enums.Code:
    if not interaction_name in interactions:
        return Enums.Code.NOT_MODIFIED
    interactions[interaction_name].unlisten(me)
    interactions.erase(interaction_name)
    record(interaction_name, "remove")
    Msg.send_interaction_remove(me, interaction_name)
    return Enums.Code.OK

## 有没有装某个交互。被谁用：条件判定/指令。
func check_exist(interaction_name: String) -> bool:
    return interactions.has(interaction_name)
