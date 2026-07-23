class_name Interactions
extends RefCounted


var me: Character
var interactions: Dictionary[String, InteractionType] = {}

func _init(me: Character, interactions_name: Array[String]) -> void:
    self.me = me
    add_interactions(interactions_name)

func add_interactions(interactions_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in interactions_name:
        codes.append(add_interaction(name))
    return codes

func add_interaction(interaction_name: String) -> Enums.Code:
    if interaction_name in interactions:
        return Enums.Code.NOT_MODIFIED
    var interaction = InteractionType.get_(interaction_name)
    interactions[interaction_name] = interaction
    interaction.listen(me)
    MsgHubChar.send_interaction_add(me, interaction_name)
    return Enums.Code.OK

func remove_interactions(interactions_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in interactions_name:
        codes.append(remove_interaction(name))
    return codes

func remove_interaction(interaction_name: String) -> Enums.Code:
    if not interaction_name in interactions:
        return Enums.Code.NOT_MODIFIED
    interactions[interaction_name].unlisten(me)
    interactions.erase(interaction_name)
    MsgHubChar.send_interaction_remove(me, interaction_name)
    return Enums.Code.OK

func check_interaction(interaction_name: String) -> bool:
    return interactions.has(interaction_name)
