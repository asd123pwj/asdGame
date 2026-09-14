class_name Collision_Area
extends BaseClass
## 碰撞区实现：给角色身体挂一个 Area2D（圆形，半径 100），进出时广播碰撞消息。
## 被谁用：CollisionPreset（collision_name = "Collision_Area" 的预设，由它 new 出来）。

## 所属角色。被谁用：广播消息时作为主体。
var me: Character
## 碰撞区名（= CollisionPreset.name）。被谁用：广播消息时作为"哪个区"。
var name: String
## 探测区节点（Area2D）。被谁用：attach（建）、进出回调。
var hitbox: Area2D

## 构造即尝试挂载（没有身体时会跳过，等 Collisions.attach_collisions 再挂）。
## 被谁用：CollisionPreset.listen。
func _init(char_: Character, name_: String, _config: Array):
    me = char_
    name = name_
    attach()

## 有 body 才建探测区；无 body 时跳过，待 body 生成后由 Collisions.attach_collisions 再调
## 被谁用：_init、CollisionPreset.attach。
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


## 有东西进入 → 广播（带对方身体节点，便于上层取 meta 里的 character）。
## 被谁用：Area2D.body_entered 信号。
func _on_body_entered(body: Node):
    if body.has_meta("character"):
        var char_: Character = body.get_meta("character", null)
        if char_:
            # print(char_.name)
            pass  
    Msg.send_collision_enter(me, name, body)

## 有东西离开 → 广播。
## 被谁用：Area2D.body_exited 信号。
func _on_body_exited(body: Node):
    if body.has_meta("character"):
        var char_: Character = body.get_meta("character", null)
        if char_:
            # print(char_.name)
            pass  
    Msg.send_collision_exit(me, name, body)
