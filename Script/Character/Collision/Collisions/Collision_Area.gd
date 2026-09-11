class_name Collision_Area
extends BaseClass

var me: Character
var name: String
var hitbox: Area2D

func _init(char_: Character, name_: String, _config: Array):
    me = char_
    name = name_
    attach()

## 有 body 才建探测区；无 body 时跳过，待 body 生成后由 Collisions.attach_collisions 再调
func attach() -> void:
    if hitbox != null or me.body == null:
        return

    hitbox = Area2D.new()

    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 100
    collision.shape = shape

    hitbox.add_child(collision)

    me.body.add_child(hitbox)
    hitbox.body_entered.connect(_on_body_entered)
    hitbox.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node):
    if body.has_meta("character"):
        var char_: Character = body.get_meta("character", null)
        if char_:
            # print(char_.name)
            pass  
    Msg.send_collision_enter(me, name, body)

func _on_body_exited(body: Node):
    if body.has_meta("character"):
        var char_: Character = body.get_meta("character", null)
        if char_:
            # print(char_.name)
            pass  
    Msg.send_collision_exit(me, name, body)