class_name Collisions
extends BaseClass
## 某角色的碰撞区集合（增删查 + 身体就绪后统一挂载）。
## 被谁用：Character.collisions（角色装配时建）；状态的 Detect 判定。

## 所属角色。被谁用：各 add/remove/attach（给预设的回调用）。
var me: Character
## 已装的碰撞区：预设名 -> 预设。被谁用：check_collision、attach_collisions。
var collisions: Dictionary[String, CollisionPreset] = {}


## 装配：记下所属角色并装入原型声明的碰撞区。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, collision_name: Array[String]) -> void:
    self.me = me
    add_collisions(collision_name)



""" ---------- init ---------- """
## 批量加（返回每个结果码）。被谁用：_init、运行时批量加碰撞区。
func add_collisions(collision_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in collision_name:
        codes.append(add_collision(name))
    return codes

## 加一个碰撞区：装进字典 → 让预设给本角色造实例 → 广播。重复加返回 NOT_MODIFIED。
## 被谁用：add_collisions、指令。
func add_collision(collision_name: String) -> Enums.Code:
    if collision_name in collisions:
        return Enums.Code.NOT_MODIFIED
    var collision = CollisionPreset.get_(collision_name)
    collisions[collision_name] = collision
    collision.listen(me)
    Msg.send_collision_add(me, collision_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除碰撞区。
func remove_collisions(collision_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in collision_name:
        codes.append(remove_collision(name))
    return codes

## 移除一个碰撞区（注意：当前只有从字典里摘 + 广播，没退订/释放探测区节点）。
## 被谁用：remove_collisions、指令。
func remove_collision(collision_name: String) -> Enums.Code:
    if not collision_name in collisions:
        return Enums.Code.NOT_MODIFIED
    # collisions[collision_name].unlisten(me)
    collisions.erase(collision_name)
    Msg.send_collision_remove(me, collision_name)
    return Enums.Code.OK

## 有没有装某个碰撞区。被谁用：状态/条件判定。
func check_collision(collision_name: String) -> bool:
    return collisions.has(collision_name)

## body 生成后，把已装碰撞区的探测体挂到 body 上
## 被谁用：Character.ensure_body（身体就绪时补挂）。
func attach_collisions() -> void:
    for collision: CollisionPreset in collisions.values():
        collision.attach(me)
