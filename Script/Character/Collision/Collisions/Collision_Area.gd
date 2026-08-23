class_name Collision_Area
extends RefCounted

var me: Character
var name: String
var hitbox: Area2D

func _init(char_: Character, name_: String, _config: Array):
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
    var char_: Character = body.get_meta("character", null)
    if char_:
        # print(char_.name)
        pass  
    MsgHubChar.send_collision_enter(me, name, body)

func _on_body_exited(body: Node):
    var char_: Character = body.get_meta("character", null)
    if char_:
        # print(char_.name)
        pass  
    MsgHubChar.send_collision_exit(me, name, body)