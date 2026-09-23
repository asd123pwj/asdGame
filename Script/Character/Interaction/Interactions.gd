class_name Interactions
extends BaseClass
## 某角色的交互集合（增删查）。交互的实现与触发条件都在 InteractionPreset 里。
## 被谁用：Character.interactions（角色装配时建）；指令里按名增删。

## 所属角色。被谁用：add/remove（传给预设去 listen/unlisten）。
var me: Character
## 已装交互：预设名 -> 预设。被谁用：check_exist、remove。
var interactions: Dictionary[String, InteractionPreset] = {}

## 动作流水（加装 / 移除 / 触发）：实现见 `ActionHistory`（技能那边共用同一份，别再写一遍 record）。
## **为什么要记**：交互触发只持续一帧（见 InteractionPreset.listen），跑过去就没了——记一笔才看得出
## "刚才到底触发没触发 / 什么时候加的 / 什么时候被移除的"（角色交互一览就照它显示"最近执行"）。
## 被谁用：add_interaction / remove_interaction（自己记）、InteractionPreset.listen（记 act）、
##         UI_Interaction（读它显示）。
var history: ActionHistory = ActionHistory.new()

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
    # 增 / 删是**结构变化**：流水照记，广播也照发（限流只挡"高频"那类，见 ActionHistory）
    history.record(interaction_name, "add")
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
    history.record(interaction_name, "remove")
    Msg.send_interaction_remove(me, interaction_name)
    return Enums.Code.OK

## 有没有装某个交互。被谁用：条件判定/指令。
func check_exist(interaction_name: String) -> bool:
    return interactions.has(interaction_name)
