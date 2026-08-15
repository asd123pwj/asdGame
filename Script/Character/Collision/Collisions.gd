class_name Collisions
extends RefCounted


var me: Character
var collisions: Dictionary[String, CollisionPreset] = {}


func _init(me: Character, collision_name: Array[String]) -> void:
    self.me = me
    add_collisions(collision_name)



""" ---------- init ---------- """
func add_collisions(collision_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in collision_name:
        codes.append(add_collision(name))
    return codes

func add_collision(collision_name: String) -> Enums.Code:
    if collision_name in collisions:
        return Enums.Code.NOT_MODIFIED
    var collision = CollisionPreset.get_(collision_name)
    collisions[collision_name] = collision
    collision.listen(me)
    MsgHubChar.send_collision_add(me, collision_name)
    return Enums.Code.OK

func remove_collisions(collision_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in collision_name:
        codes.append(remove_collision(name))
    return codes

func remove_collision(collision_name: String) -> Enums.Code:
    if not collision_name in collisions:
        return Enums.Code.NOT_MODIFIED
    collisions[collision_name].unlisten(me)
    collisions.erase(collision_name)
    MsgHubChar.send_collision_remove(me, collision_name)
    return Enums.Code.OK

func check_collision(collision_name: String) -> bool:
    return collisions.has(collision_name)
