class_name BodyPreset
extends PresetRegister
## 身体预设：一张贴图路径 = 一种身体外观，create() 现场搭出 CharacterBody2D。
## 被谁用：Character.ensure_body、Archetype 的 bodies 字段。

## 预设名（唯一）。被谁用：BodyPreset.get_、Character.ensure_body。
var name: String
## 贴图资源路径。被谁用：create。
var sprite_path: String

## 全部预设：名 -> 实例。被谁用：BodyPreset.get_。
static var _we: Dictionary[String, BodyPreset] = {}

## 注册一条身体预设。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, sprite_path: String) -> void:
    _we[name] = self
    self.name = name
    self.sprite_path = sprite_path

## 按名取预设。被谁用：Character.ensure_body。
static func get_(name: String) -> BodyPreset:
    return _we[name]

## 造一个身体：CharacterBody2D + 精灵 + 与贴图同尺寸的矩形碰撞体，直接挂到当前场景。
## 被谁用：Character.ensure_body。
func create() -> CharacterBody2D:
    # 1. 创建物理身体
    var body = CharacterBody2D.new()
    
    # 2. 创建精灵（同上）
    var texture: Texture2D = load(sprite_path)
    var sprite = Sprite2D.new()
    sprite.texture = texture
    body.add_child(sprite)
    
    # 3. 创建碰撞体（比如圆形或矩形）
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = texture.get_size()
    collision.shape = shape
    body.add_child(collision)
    
    # 4. 添加到场景
    Sys.sys.get_tree().current_scene.add_child(body)
    return body
