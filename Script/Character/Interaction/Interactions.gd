class_name Interactions
extends BaseClass
## 某角色的交互集合（增删查）。交互的实现与触发条件都在 InteractionPreset 里。
## 被谁用：Character.interactions（角色装配时建）；指令里按名增删。

## 所属角色。被谁用：add/remove（传给预设去 listen/unlisten）。
var me: Character
## 已装交互：预设名 -> 预设。被谁用：check_exist、remove。
var interactions: Dictionary[String, InteractionPreset] = {}

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
    Msg.send_interaction_remove(me, interaction_name)
    return Enums.Code.OK

## 有没有装某个交互。被谁用：条件判定/指令。
func check_exist(interaction_name: String) -> bool:
    return interactions.has(interaction_name)
