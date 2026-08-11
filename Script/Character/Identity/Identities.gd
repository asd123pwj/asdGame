# class_name Identities
# extends RefCounted


# var me: Character
# var identities: Dictionary[String, Identity] = {}

# func _init(me: Character, identity_name: Array[String]) -> void:
#     self.me = me
#     add_identities(identity_name)


# func check_satisfied(identity_name: String) -> bool:
#     if not check_identity(identity_name):
#         return false
#     return identities[identity_name].satisfied[me]

# """ ---------- Listeners ---------- """
# func add_identities(identity_name: Array[String]) -> Array[Enums.Code]:
#     var codes: Array[Enums.Code] = []
#     for name in identity_name:
#         codes.append(add_identity(name))
#     return codes

# func add_identity(identity_name: String) -> Enums.Code:
#     if identities.has(identity_name):
#         return Enums.Code.NOT_MODIFIED
#     var identity: Identity = Identity.get_(identity_name)
#     identities[identity_name] = identity
#     identity.listen(me)
#     MsgHubChar.send_identity_add(me, identity_name)
#     return Enums.Code.OK

# func remove_identities(identity_name: Array[String]) -> Array[Enums.Code]:
#     var codes: Array[Enums.Code] = []
#     for name in identity_name:
#         codes.append(remove_identity(name))
#     return codes

# func remove_identity(identity_name: String) -> Enums.Code:
#     if not identities.has(identity_name):
#         return Enums.Code.NOT_MODIFIED
#     identities[identity_name].unlisten(me)
#     identities.erase(identity_name)
#     MsgHubChar.send_identity_remove(me, identity_name)
#     return Enums.Code.OK

# func check_identity(identity_name: String) -> bool:
#     return identities.has(identity_name)
