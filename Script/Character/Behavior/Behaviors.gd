class_name Behaviors
extends RefCounted


var me: Character
var behaviors: Dictionary[String, BehaviorType] = {}

func _init(me: Character, behavior_name: Array[String]) -> void:
    self.me = me
    add_behaviors(behavior_name)

func add_behaviors(behavior_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in behavior_name:
        codes.append(add_behavior(name))
    return codes

func add_behavior(behavior_name: String) -> Enums.Code:
    if behavior_name in behaviors:
        return Enums.Code.NOT_MODIFIED
    var behavior = BehaviorType.get_(behavior_name)
    behaviors[behavior_name] = behavior
    behavior.listen(me)
    MsgHubChar.send_behavior_add(me, behavior_name)
    return Enums.Code.OK

func remove_behaviors(behavior_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in behavior_name:
        codes.append(remove_behavior(name))
    return codes

func remove_behavior(behavior_name: String) -> Enums.Code:
    if not behavior_name in behaviors:
        return Enums.Code.NOT_MODIFIED
    behaviors[behavior_name].unlisten(me)
    behaviors.erase(behavior_name)
    MsgHubChar.send_behavior_remove(me, behavior_name)
    return Enums.Code.OK

func check_behavior(behavior_name: String) -> bool:
    return behaviors.has(behavior_name)

# func get_behavior(behavior_name: String) -> Behaviors:
#     if not behavior_name in self.behaviors:
#         return null
#     return self.me.get_behavior(behavior_name)
