class_name CollisionPreset
extends PresetRegister
## 碰撞区预设：一个"探测区"（Area2D）的声明——用哪个实现类、什么参数。
## 角色"进入/离开"这个区时，会触发状态判定（如 Detect=>Touch）。
## 被谁用：Collisions.add_collision（装到角色身上）、Archetype 的 collisions 字段。
## 注意：预设是共享的，所以"每个角色的探测区实例"存在 collision_objs 里按角色分开。

## 预设名（唯一）。被谁用：Collisions 的字典键、状态的 detect 名。
var name: String
## 实现类名（BaseClass 子类，如 "Collision_Area"）。被谁用：_get_collision_by_name。
var collision_name: String
## 传给实现类的参数。被谁用：listen。
var config: Array
## 实现类脚本。被谁用：listen（实例化）。
var collision 

## 每个角色各自的探测区实例。被谁用：listen（建）、attach（挂到身体）。
var collision_objs: Dictionary[Character, Variant] = {}

## 全部预设：名 -> 实例。被谁用：CollisionPreset.get_。
static var _we: Dictionary[String, CollisionPreset] = {}

## 注册一条碰撞预设，并按类名找到实现脚本。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, collision_name: String, config: Array = []) -> void:
    _we[name] = self
    self.name = name
    self.collision_name = collision_name
    self.config = config
    _get_collision_by_name()

## 按类名从全局类表里取实现脚本（取不到报错）。
## 被谁用：_init。
func _get_collision_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == collision_name:
            collision = load(cls["path"])
            return
    push_error("找不到类: ", collision_name)
    collision = null

## 按名取预设。被谁用：Collisions.add_collision。
static func get_(name: String) -> CollisionPreset:
    return _we[name]

## 给某个角色造一份自己的探测区实例（构造时会尝试 attach，没身体就等后面补）。
## 被谁用：Collisions.add_collision。
func listen(char_: Character) -> void:
    @warning_ignore("unsafe_method_access")
    collision_objs[char_] = collision.new(char_, name, config)

## 把该角色的探测区挂到它的身体上（身体生成后才可能成功）。
## 被谁用：Collisions.attach_collisions。
func attach(char_: Character) -> void:
    @warning_ignore("unsafe_method_access")
    collision_objs[char_].attach()
