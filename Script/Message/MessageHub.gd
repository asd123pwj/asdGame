class_name Msg
extends MsgBus

"""
为了方便用Msg.send统一发送消息，而不是MsgHubChar这么长
我把它们统一放到一个文件下，但这个文件太长了，不好定位
所以我用下面的ASCII艺术进行分割，它在VSCode右侧预览侧显示的很好
https://patorjk.com/software/taag/#p=display&f=Terrace&t=System&x=none&v=4&h=4&w=200&we=true
"""
"""
  ░██████                            ░██                               
 ░██   ░██                           ░██                               
░██         ░██    ░██  ░███████  ░████████  ░███████  ░█████████████  
 ░████████  ░██    ░██ ░██           ░██    ░██    ░██ ░██   ░██   ░██ 
        ░██ ░██    ░██  ░███████     ░██    ░█████████ ░██   ░██   ░██ 
 ░██   ░██  ░██   ░███        ░██    ░██    ░██        ░██   ░██   ░██ 
  ░██████    ░█████░██  ░███████      ░████  ░███████  ░██   ░██   ░██ 
                   ░██                                                 
             ░███████                                                  
"""
""" ---------- Spawn or Destory ---------- """
static func send_char_create(char_: Character) -> Array:
    return super.send("CHAR_CREATE", char_)

static func send_spawn(char_: Character) -> Array:
    return super.send("SPAWN", char_)

static func send_destory(char_: Character) -> Array:
    return super.send("DESTORY", char_)


static func listen_char_create(callback: Callable) -> String:
    return super.listen("CHAR_CREATE", callback)

static func listen_spawn(callback: Callable) -> String:
    return super.listen("SPAWN", callback)

static func listen_destory(callback: Callable) -> String:
    return super.listen("DESTORY", callback)


"""      
░██████████   ░██                              
    ░██                                        
    ░██       ░██   ░█████████████   ░███████  
    ░██       ░██   ░██   ░██   ░██ ░██    ░██ 
    ░██       ░██   ░██   ░██   ░██ ░█████████ 
    ░██       ░██   ░██   ░██   ░██ ░██        
    ░██       ░██   ░██   ░██   ░██  ░███████  
"""
""" ---------- Basic ---------- """
static func _format_time(type: String) -> String:
    return format_ID(["TIME", type])

static func _send_time(type: String, message: Variant) -> Array:
    return send(_format_time(type), message)

static func _listen_time(type: String, callback: Callable) -> String:
    return listen(_format_time(type), callback)

""" ---------- ADVANCE ---------- """
static func send_tick(message: Variant = null) -> Array:
    return _send_time("TICK", message)

static func listen_tick(callback: Callable) -> String:
    return _listen_time("TICK", callback)

""" ---------- ADVANCE ---------- """
static func send_advance_year(message: Variant) -> Array:
    return _send_time("ADVANCE_YEAR", message)

static func send_advance_month(message: Variant) -> Array:
    return _send_time("ADVANCE_MONTH", message)

static func send_advance_xun(message: Variant) -> Array:
    return _send_time("ADVANCE_XUN", message)

static func send_advance_day(message: Variant) -> Array:
    return _send_time("ADVANCE_DAY", message)

static func send_advance_hour(message: Variant) -> Array:
    return _send_time("ADVANCE_HOUR", message)

# static func send_advance(message: Variant) -> Array:
#     return _send_time("ADVANCE", message)

static func listen_advance_year(callback: Callable) -> String:
    return _listen_time("ADVANCE_YEAR", callback)

static func listen_advance_month(callback: Callable) -> String:
    return _listen_time("ADVANCE_MONTH", callback)

static func listen_advance_xun(callback: Callable) -> String:
    return _listen_time("ADVANCE_XUN", callback)

static func listen_advance_day(callback: Callable) -> String:
    return _listen_time("ADVANCE_DAY", callback)

static func listen_advance_hour(callback: Callable) -> String:
    return _listen_time("ADVANCE_HOUR", callback)

# static func listen_advance(callback: Callable) -> String:
#     return _listen_time("ADVANCE", callback)



"""
░██████                                    ░██    
  ░██                                      ░██    
  ░██  ░████████  ░████████  ░██    ░██ ░████████ 
  ░██  ░██    ░██ ░██    ░██ ░██    ░██    ░██    
  ░██  ░██    ░██ ░██    ░██ ░██    ░██    ░██    
  ░██  ░██    ░██ ░███   ░██ ░██   ░███    ░██    
░██████░██    ░██ ░██░█████   ░█████░██     ░████ 
                  ░██                             
                  ░██                             
                                                  
"""

""" ---------- Single Key Basic ---------- """
static func _format_input(key: Variant, status: Enums.KeyStatus) -> String:
    if typeof(key) == TYPE_ARRAY:
        return format_ID(["Input", " ".join(key), str(status)])
    else:
        return format_ID(["Input", str(key), str(status)])

static func _send_input(key: Variant, status: Enums.KeyStatus) -> Array:
    var results := send(_format_input(key, status), [key, status])
    # 这个写完我还没测试过，或者说，所有unlisten我都没测试过
    if results.is_empty() and (typeof(key) == TYPE_ARRAY):
        InputCombo.unlisten(key)
    return results
        
static func _listen_input(key: Variant, status: Enums.KeyStatus, callback: Callable) -> String:
    if typeof(key) == TYPE_ARRAY:
        InputCombo.add_if_not_exist(key)
    return listen(_format_input(key, status), callback)

""" ---------- Single Key ---------- """
static func send_key_down(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.DOWN)

static func send_key_first_down(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.FIRST_DOWN)

# static func send_key_up(key: Variant) -> Array:
#     return _send_input(key, Enums.KeyStatus.UP)

static func send_key_first_up(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.FIRST_UP)

static func listen_key_down(key: Variant, callback: Callable) -> String:
    return _listen_input(key, Enums.KeyStatus.DOWN, callback)

static func listen_key_first_down(key: Variant, callback: Callable) -> String:
    return _listen_input(key, Enums.KeyStatus.FIRST_DOWN, callback)

# static func listen_key_up(key: Variant, callback: Callable) -> String:
#     return _listen_input(key, Enums.KeyStatus.UP, callback)

static func listen_key_first_up(key: Variant, callback: Callable) -> String:
    return _listen_input(key, Enums.KeyStatus.FIRST_UP, callback)

    

"""
  ░██████                         ░██ 
 ░██   ░██                        ░██ 
░██        ░█████████████   ░████████ 
░██        ░██   ░██   ░██ ░██    ░██ 
░██        ░██   ░██   ░██ ░██    ░██ 
 ░██   ░██ ░██   ░██   ░██ ░██   ░███ 
  ░██████  ░██   ░██   ░██  ░█████░██ 
"""
static func send_cmd(message: Variant) -> Array:
    return super.send("COMMAND", message)
# 快速取多条指令的结果
static func send_cmd0(message: Variant) -> Variant:
    return send_cmd(message)[0]
# 快速取单条指令的结果
static func send_cmd00(message: Variant) -> Variant:
    return send_cmd(message)[0][0]

static func listen_cmd(callback: Callable) -> String:
    return super.listen("COMMAND", callback)



"""
  ░██████  ░██                            
 ░██   ░██ ░██                            
░██        ░████████   ░██████   ░██░████ 
░██        ░██    ░██       ░██  ░███     
░██        ░██    ░██  ░███████  ░██      
 ░██   ░██ ░██    ░██ ░██   ░██  ░██      
  ░██████  ░██    ░██  ░█████░██ ░██                                            
"""

""" ---------- Basic ---------- """
static func _format_character(char_: Character, type: String, type_name: String, action: String) -> String:
    return format_ID(["CHAR", str(char_.ID), type, type_name, action])

static func _send_character(char_: Character, type: String, type_name: String, action: String, message:Variant = null) -> Array:
    var node_ID = _format_character(char_, type, type_name, action)
    if message != null:
        return send(node_ID, message)
    return send(node_ID, char_)

static func _listen_character(char_: Character, type: String, type_name: String, action: String, callback: Callable) -> String:
    var node_ID = _format_character(char_, type, type_name, action)
    return listen(node_ID, callback)

static func _get_message_character(char_: Character, type: String, type_name: String, action: String) -> Variant:
    var node_ID = _format_character(char_, type, type_name, action)
    return get_message(node_ID)

"""
                   ░███       ░██       ░██             
                  ░██░██      ░██       ░██             
                 ░██  ░██  ░████████ ░████████ ░██░████ 
░██████ ░██████ ░█████████    ░██       ░██    ░███     
                ░██    ░██    ░██       ░██    ░██      
                ░██    ░██    ░██       ░██    ░██      
                ░██    ░██     ░████     ░████ ░██      
"""
""" ---------- Attributes ---------- """
static func send_attr_changed(char_: Character, type_name: String) -> Array:
    send_any_attr_changed(char_, type_name)
    return _send_character(char_, "ATTR", type_name, "changed")

static func send_any_attr_changed(char_: Character, type_name: String) -> Array:
    return _send_character(char_, "ANY_ATTR", "ANY", "changed", type_name)

static func listen_attr_changed(char_: Character, type_name: String, callback: Callable) -> String:
    return _listen_character(char_, "ATTR", type_name, "changed", callback)

static func listen_any_attr_changed(char_: Character, callback: Callable) -> String:
    return _listen_character(char_, "ANY_ATTR", "ANY", "changed", callback)



"""
                ░████████                  ░████     ░████ 
                ░██    ░██                ░██       ░██    
                ░██    ░██  ░██    ░██ ░████████ ░████████ 
░██████ ░██████ ░████████   ░██    ░██    ░██       ░██    
                ░██     ░██ ░██    ░██    ░██       ░██    
                ░██     ░██ ░██   ░███    ░██       ░██    
                ░█████████   ░█████░██    ░██       ░██                                                         
"""
""" ---------- BuffPreset ---------- """
static func send_buff_add(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "add")

static func send_buff_remove(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "remove")

static func send_buff_consume(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "consume")

static func send_buff_depleted(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "depleted")

static func listen_buff_add(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen_character(char_, "BUFF", buff_name, "add", callback)

static func listen_buff_remove(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen_character(char_, "BUFF", buff_name, "remove", callback)

static func listen_buff_consume(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen_character(char_, "BUFF", buff_name, "consume", callback)

static func listen_buff_depleted(char_: Character, buff_name: String, callback: Callable) -> String:
    return _listen_character(char_, "BUFF", buff_name, "depleted", callback)


"""
                  ░██████      ░██                  ░██                          
                 ░██   ░██     ░██                  ░██                          
                ░██         ░████████  ░██████   ░████████ ░██    ░██  ░███████  
░██████ ░██████  ░████████     ░██          ░██     ░██    ░██    ░██ ░██        
                        ░██    ░██     ░███████     ░██    ░██    ░██  ░███████  
                 ░██   ░██     ░██    ░██   ░██     ░██    ░██   ░███        ░██ 
                  ░██████       ░████  ░█████░██     ░████  ░█████░██  ░███████                                                                             
"""

""" ---------- Character Statuses Listener ---------- """
static func send_status_satisfied(char_: Character, status_name: String) -> Array:
    return _send_character(char_, "STATUS", status_name, "satisfied")

static func send_status_unsatisfied(char_: Character, status_name: String) -> Array:
    return _send_character(char_, "STATUS", status_name, "unsatisfied")

static func send_status_add(char_: Character, status_name: String) -> Array:
    return _send_character(char_, "STATUS", status_name, "add")

static func send_status_remove(char_: Character, status_name: String) -> Array:
    return _send_character(char_, "STATUS", status_name, "remove")

## detect来传入目标，例如碰撞体接触，先detect发送接触目标以在消息节点记录，
## 再发送前面的send_status_enable令Touch状态为真，进而触发interaction，
## 而interaction内部用get_interaction_target去消息节点里面读取目标，
## 这样把target和status分开，不然不知道怎么target怎么告诉对应交互
##
## 现在状态可以监听交互了，我简直天才，当然它还是可以用于发消息
static func send_status_detected(char_: Character, status_name: String, target: Variant = null) -> Array:
    return _send_character(char_, "STATUS", status_name, "detected", target)

## 我觉得这玩意用不到
# static func send_status_undetected(char_: Character, status_name: String, target: Variant) -> Array:
#     return _send_character(char_, "STATUS", status_name, "undetected", target)

static func listen_status_satisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen_character(char_, "STATUS", status_name, "satisfied", callback)

static func listen_status_unsatisfied(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen_character(char_, "STATUS", status_name, "unsatisfied", callback)

static func listen_status_add(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen_character(char_, "STATUS", status_name, "add", callback)

static func listen_status_remove(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen_character(char_, "STATUS", status_name, "remove", callback)

static func listen_status_detected(char_: Character, status_name: String, callback: Callable) -> String:
    return _listen_character(char_, "STATUS", status_name, "detected", callback)

## 我觉得这玩意用不到
# static func listen_status_undetected(char_: Character, status_name: String, callback: Callable) -> String:
#     return _listen_character(char_, "STATUS", status_name, "undetected", callback)

static func get_status_detected(char_: Character, interaction_name: String) -> Variant:
    return _get_message_character(char_, "STATUS", interaction_name, "detected")

## 我觉得这玩意用不到
static func get_status_undetected(char_: Character, interaction_name: String) -> Variant:
    return _get_message_character(char_, "STATUS", interaction_name, "undetected")



""" ---------- Character Behaviors ---------- """
# static func send_behavior_add(char_: Character, behavior_name: String) -> Array:
#     return _send_character(char_, "BEHAVIOR", behavior_name, "add")

# static func send_behavior_remove(char_: Character, behavior_name: String) -> Array:
#     return _send_character(char_, "BEHAVIOR", behavior_name, "remove")

# static func send_behavior_act(char_: Character, behavior_name: String) -> Array:
#     return _send_character(char_, "BEHAVIOR", behavior_name, "act")

# static func listen_behavior_add(char_: Character, behavior_name: String, callback: Callable) -> String:
#     return _listen_character(char_, "BEHAVIOR", behavior_name, "add", callback)

# static func listen_behavior_remove(char_: Character, behavior_name: String, callback: Callable) -> String:
#     return _listen_character(char_, "BEHAVIOR", behavior_name, "remove", callback)

# static func listen_behavior_act(char_: Character, behavior_name: String, callback: Callable) -> String:
#     return _listen_character(char_, "BEHAVIOR", behavior_name, "act", callback)

    
"""
                ░██████              ░██                                                 ░██    
                  ░██                ░██                                                 ░██    
                  ░██  ░████████  ░████████  ░███████  ░██░████  ░██████    ░███████  ░████████ 
░██████ ░██████   ░██  ░██    ░██    ░██    ░██    ░██ ░███           ░██  ░██    ░██    ░██    
                  ░██  ░██    ░██    ░██    ░█████████ ░██       ░███████  ░██           ░██    
                  ░██  ░██    ░██    ░██    ░██        ░██      ░██   ░██  ░██    ░██    ░██    
                ░██████░██    ░██     ░████  ░███████  ░██       ░█████░██  ░███████      ░████ 
                                                                                                
                                                                                                
                                                                                                
"""
""" ---------- Character InteractionPreset ---------- """
static func send_interaction_add(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "add")

static func send_interaction_remove(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "remove")
    
static func send_interaction_act(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "act")
    
static func listen_interaction_add(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "add", callback)

static func listen_interaction_remove(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "remove", callback)

static func listen_interaction_act(char_: Character, interaction_name: String, callback: Callable) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "act", callback)



"""
                  ░██████   ░██          ░██   ░██    ░██ 
                 ░██   ░██  ░██                ░██    ░██ 
                ░██         ░██    ░██   ░██   ░██    ░██ 
░██████ ░██████  ░████████  ░██   ░██    ░██   ░██    ░██ 
                        ░██ ░███████     ░██   ░██    ░██ 
                 ░██   ░██  ░██   ░██    ░██   ░██    ░██ 
                  ░██████   ░██    ░██   ░██   ░██    ░██ 
                                                          
                                                          
                                                          
"""
""" ---------- Character Skills ---------- """
static func send_skill_add(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "add")

static func send_skill_remove(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "remove")

static func send_skill_act(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "act")

static func listen_skill_add(char_: Character, skill_name: String, callback: Callable) -> String:
    return _listen_character(char_, "SKILL", skill_name, "add", callback)

static func listen_skill_remove(char_: Character, skill_name: String, callback: Callable) -> String:
    return _listen_character(char_, "SKILL", skill_name, "remove", callback)

static func listen_skill_act(char_: Character, skill_name: String, callback: Callable) -> String:
    return _listen_character(char_, "SKILL", skill_name, "act", callback)


"""
                  ░██████             ░██ ░██ ░██           ░██                      
                 ░██   ░██            ░██ ░██                                        
                ░██         ░███████  ░██ ░██ ░██ ░███████  ░██ ░███████  ░████████  
░██████ ░██████ ░██        ░██    ░██ ░██ ░██ ░██░██        ░██░██    ░██ ░██    ░██ 
                ░██        ░██    ░██ ░██ ░██ ░██ ░███████  ░██░██    ░██ ░██    ░██ 
                 ░██   ░██ ░██    ░██ ░██ ░██ ░██       ░██ ░██░██    ░██ ░██    ░██ 
                  ░██████   ░███████  ░██ ░██ ░██ ░███████  ░██ ░███████  ░██    ░██                                                                                 
"""

""" ---------- Character CollisionPreset ---------- """
static func send_collision_add(char_: Character, collision_name: String) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "add")

static func send_collision_remove(char_: Character, collision_name: String) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "remove")

static func send_collision_enter(char_: Character, collision_name: String, body: Node) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "enter", body)

static func send_collision_exit(char_: Character, collision_name: String, body: Node) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "exit", body)

static func listen_collision_add(char_: Character, collision_name: String, callback: Callable) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "add", callback)

static func listen_collision_remove(char_: Character, collision_name: String, callback: Callable) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "remove", callback)

static func listen_collision_enter(char_: Character, collision_name: String, callback: Callable) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "enter", callback)

static func listen_collision_exit(char_: Character, collision_name: String, callback: Callable) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "exit", callback)


"""
                ░██████                                               ░██                                   
                  ░██                                                 ░██                                   
                  ░██  ░████████  ░██    ░██  ░███████  ░████████  ░████████  ░███████  ░██░████ ░██    ░██ 
░██████ ░██████   ░██  ░██    ░██ ░██    ░██ ░██    ░██ ░██    ░██    ░██    ░██    ░██ ░███     ░██    ░██ 
                  ░██  ░██    ░██  ░██  ░██  ░█████████ ░██    ░██    ░██    ░██    ░██ ░██      ░██    ░██ 
                  ░██  ░██    ░██   ░██░██   ░██        ░██    ░██    ░██    ░██    ░██ ░██      ░██   ░███ 
                ░██████░██    ░██    ░███     ░███████  ░██    ░██     ░████  ░███████  ░██       ░█████░██ 
                                                                                                        ░██ 
                                                                                                  ░███████                                                                                      
"""
""" ---------- Character Inventory ---------- """
static func send_inventory_add(char_: Character, inventory_name: String) -> Array:
    return _send_character(char_, "INVENTORY", inventory_name, "add")

static func send_inventory_remove(char_: Character, inventory_name: String) -> Array:
    return _send_character(char_, "INVENTORY", inventory_name, "remove")


static func listen_inventory_add(char_: Character, inventory_name: String, callback: Callable) -> String:
    return _listen_character(char_, "INVENTORY", inventory_name, "add", callback)

static func listen_inventory_remove(char_: Character, inventory_name: String, callback: Callable) -> String:
    return _listen_character(char_, "INVENTORY", inventory_name, "remove", callback)
