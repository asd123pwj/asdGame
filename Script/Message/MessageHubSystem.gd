# class_name Msg
# extends MsgBus


# """ ---------- Spawn or Destory ---------- """
# static func send_char_create(char_: Character) -> Array:
#     return super.send("CHAR_CREATE", char_)

# static func send_spawn(char_: Character) -> Array:
#     return super.send("SPAWN", char_)

# static func send_destory(char_: Character) -> Array:
#     return super.send("DESTORY", char_)


# static func listen_char_create(callback: Callable) -> String:
#     return super.listen("CHAR_CREATE", callback)

# static func listen_spawn(callback: Callable) -> String:
#     return super.listen("SPAWN", callback)

# static func listen_destory(callback: Callable) -> String:
#     return super.listen("DESTORY", callback)