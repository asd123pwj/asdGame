class_name Area
extends RefCounted

var me: Character
var name: String
var hitbox: CollisionObject2D

func _init(char_: Character, name_: String, config: Array):
    me = char_
    name = name_

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
    print("a")
    MsgHubChar.send_collision_enter(me, name, body)

func _on_body_exited(body: Node):
    MsgHubChar.send_collision_exit(me, name, body)