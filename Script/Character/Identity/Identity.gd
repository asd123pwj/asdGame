# class_name Identity
# extends PresetRegister


# """ ---------- individual ---------- """
# """ ----- Config ----- """
# var name: String


# """ ----- Global ----- """
# static var _we: Dictionary[String, Identity] = {}


# """ ---------- Init ---------- """
# ## allow_negative 新等级是否可低于level_min。如血量true（死亡），金币false（购买失败）
# func _init(
#         name: String,
#         ) -> void:
#     _we[name] = self
#     self.name = name

# static func get_(name: String) -> Identity:
#     return _we[name]
