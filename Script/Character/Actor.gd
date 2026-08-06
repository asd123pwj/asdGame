# class_name Actor
# extends RefCounted


# var me: Character
# var race_name: String
# var body: CharacterBody2D

# func _init(me: Character, race_name: String) -> void:
#     self.me = me
#     self.race_name = race_name
#     self.body = Body.get_(race_name).create()
#     if race_name == "Human":
#         body.position = Vector2(64, 128)
#     else:
#         body.position = Vector2(128, 128)
