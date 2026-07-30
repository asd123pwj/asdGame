class_name Body
extends PresetRegister

var name: String
var sprite_path: String

static var _we: Dictionary[String, Body] = {}

func _init(name: String, sprite_path: String) -> void:
    _we[name] = self
    self.name = name
    self.sprite_path = sprite_path

static func get_(name: String) -> Body:
    return _we[name]

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