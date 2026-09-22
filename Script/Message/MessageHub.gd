class_name Msg
extends MsgBus
## 消息层（见 Script/Message/Message.md）：本类只负责**"每种消息用什么节点 ID"**，收发在父类 MsgBus。
## 结构约定（改这里前先读这三条）：
##   1. 每个域（时间/输入/指令/角色/属性/buff/状态/交互/碰撞/背包/技能/快捷/UI/其它）一段，
##      段首有 ASCII 大标题 + `""" ---------- X ---------- """` 小标题，方便定位。
##   2. 段的 ID 规则收在段顶的 `_format_x()` 里；`_send_x()` / `_listen_x()` 是"按 ID 收发"的中间层；
##      后面成串的 `send_yyy()` / `listen_yyy()` 都是**同模板的薄包装**（一行 send / 一行 listen）。
##      所以：**改 ID 规则只改 `_format_x`；要查某条消息谁在用，直接 grep 那个 `send_/listen_` 函数名。**
##   3. 角色域的名字支持 "名字@identity"（定位到其它角色），解析与迁移见 `_resolve_target` / `_listen_character`。
##   4. 所有 `listen_*` 都能多传一个 `once = true`：**一次性监听**，广播一次后由 MsgBus 自动摘掉
##      （"临时的收尾函数"用它，就不必自己保存监听 ID 再 unlisten）。

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
## 角色生成/销毁：ID 就是固定串（无参数），全局广播。
## 被谁用：CharSys.create_char / spawn（send），以及需要感知角色出现/消失的地方（listen）。
""" ---------- Spawn or Destory ---------- """
static func send_char_create(char_: Character) -> Array:
    return super.send("CHAR_CREATE", char_)

static func send_spawn(char_: Character) -> Array:
    return super.send("SPAWN", char_)

static func send_destory(char_: Character) -> Array:
    return super.send("DESTORY", char_)


static func listen_char_create(callback: Callable, once: bool = false) -> String:
    return super.listen("CHAR_CREATE", callback, false, once)

static func listen_spawn(callback: Callable, once: bool = false) -> String:
    return super.listen("SPAWN", callback, false, once)

static func listen_destory(callback: Callable, once: bool = false) -> String:
    return super.listen("DESTORY", callback, false, once)


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
## 时间域 ID 规则：["TIME", 事件名] → "TIME->事件名"（全局广播，不带角色）。
## 被谁用：下面所有 send_tick/advance_* 与它们的 listen_（同模板薄包装）。
static func _format_time(type: String) -> String:
    return format_ID(["TIME", type])

## 按时间域规则发一条消息（供本段各 send_* 复用）。被谁用：本段各 send_*。
static func _send_time(type: String, message: Variant) -> Array:
    return send(_format_time(type), message)

## 按时间域规则登记监听（供本段各 listen_* 复用）。被谁用：本段各 listen_*。
static func _listen_time(type: String, callback: Callable, once: bool = false) -> String:
    return listen(_format_time(type), callback, false, once)

""" ---------- ADVANCE ---------- """
static func send_tick(message: Variant = null) -> Array:
    return _send_time("TICK", message)

static func listen_tick(callback: Callable, once: bool = false) -> String:
    return _listen_time("TICK", callback, once)

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

static func listen_advance_year(callback: Callable, once: bool = false) -> String:
    return _listen_time("ADVANCE_YEAR", callback, once)

static func listen_advance_month(callback: Callable, once: bool = false) -> String:
    return _listen_time("ADVANCE_MONTH", callback, once)

static func listen_advance_xun(callback: Callable, once: bool = false) -> String:
    return _listen_time("ADVANCE_XUN", callback, once)

static func listen_advance_day(callback: Callable, once: bool = false) -> String:
    return _listen_time("ADVANCE_DAY", callback, once)

static func listen_advance_hour(callback: Callable, once: bool = false) -> String:
    return _listen_time("ADVANCE_HOUR", callback, once)

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

## 单键域：一个键值（Godot 常量，如 KEY_S / MOUSE_BUTTON_LEFT）当一个"键"用，ID 见 _format_input。
## 被谁用：InputSys._send_key_status（send_key_press/release）、InputSys._process（send_key_hold）；
##          listen 侧主要是 StatusPreset 的按键监听与 InputCombo。
""" ---------- Single Key Basic ---------- """
## 输入域 ID 规则：["KEY", 键值, 状态]（键值用 Godot 常量）。
## 被谁用：下面 send_key_* / listen_key_*；再由 InputSys / StatusPreset / InputCombo 等上层调用。
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
        
static func _listen_input(key: Variant, status: Enums.KeyStatus, callback: Callable, once: bool = false) -> String:
    if typeof(key) == TYPE_ARRAY:
        InputCombo.add_if_not_exist(key)
    return listen(_format_input(key, status), callback, false, once)

## 单键（对外接口层）：与上面同域，只是把 hold/press/release 拆成便于配置引用的名字。
## 被谁用：StatusPreset.listen（按键监听）、InputCombo._listen。
## 指针移动不在这里：它不绑键位、也不经状态层（PointerDetect._process 直接派发 Pointer Move）。
""" ---------- Single Key ---------- """
static func send_key_hold(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.HOLD)

static func send_key_press(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.PRESS)

static func send_key_release(key: Variant) -> Array:
    return _send_input(key, Enums.KeyStatus.RELEASE)


static func listen_key_hold(key: Variant, callback: Callable, once: bool = false) -> String:
    return _listen_input(key, Enums.KeyStatus.HOLD, callback, once)

static func listen_key_press(key: Variant, callback: Callable, once: bool = false) -> String:
    return _listen_input(key, Enums.KeyStatus.PRESS, callback, once)

static func listen_key_release(key: Variant, callback: Callable, once: bool = false) -> String:
    return _listen_input(key, Enums.KeyStatus.RELEASE, callback, once)

    
"""
  ░██████                         ░██ 
 ░██   ░██                        ░██ 
░██        ░█████████████   ░████████ 
░██        ░██   ░██   ░██ ░██    ░██ 
░██        ░██   ░██   ░██ ░██    ░██ 
 ░██   ░██ ░██   ░██   ░██ ░██   ░███ 
  ░██████  ░██   ░██   ░██  ░█████░██ 
"""
## 指令域：send_cmd 把指令串交给 CmdSys（返回每条子指令结果数组）；
## send_cmd0 / send_cmd00 是"只要结果"的便捷版（取下标，见 test.gd 里的用法）。
## 被谁用：全项目的 Msg.send_cmd(...)（UI 事件、状态触发、快捷键、测试）。
static func send_cmd(message: Variant) -> Array:
    return super.send("COMMAND", message)
# 快速取多条指令的结果
static func send_cmd0(message: Variant) -> Variant:
    return send_cmd(message)[0]
# 快速取单条指令的结果
static func send_cmd00(message: Variant) -> Variant:
    return send_cmd(message)[0][0]

static func listen_cmd(callback: Callable, once: bool = false) -> String:
    return super.listen("COMMAND", callback, false, once)


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
## 名字支持 "名字@identity"：含 @ 时指向 CharSys.identies 里该 identity 的角色，不再用传入的 char_。
## 返回 [解析后的角色, 纯名字]。所有域的 type_name 都经此统一解析。
static func _resolve_target(char_: Character, type_name: String) -> Array:
    if "@" in type_name:
        var parts := type_name.split("@")
        var target: Character = CharSys.get_identity(parts[1])
        if target != null:
            return [target, parts[0]]
    return [char_, type_name]

static func _format_character(char_: Character, type: String, type_name: String, action: String) -> String:
    ## 角色节点用**注册名**（`Char/人类`）——ID 每次运行都变、人对不上，名字才是"能认的那个"。
    ## 指向别的角色（"名字@identity"）时，注册名也可能是那个目标的名字：所以直接问 char_ 自己叫什么。
    ## char_ 可为 null：这是"@identity 尚未解析出角色"时的占位（调用方无需自备角色），
    ## 用该 identity 造个临时标签即可——该监听随后会由 bind_identity → rebind_identity
    ## 迁到真实角色的节点上（见 _listen_character）。
    var char_ID: String
    if char_ != null:
        char_ID = RegSys.name_of(char_)
    else:
        char_ID = "@" + (type_name.split("@")[1] if "@" in type_name else "?")
    return format_ID(["CHAR", char_ID, type, type_name, action])

## 角色域通用发送：先按 "名字@identity" 解析目标，再拼 ID 发出去。
## 被谁用：本文件里角色域（属性/buff/状态/交互/碰撞/背包/技能/快捷）的**所有** send_*。
static func _send_character(char_: Character, type: String, type_name: String, action: String, message: Variant = null) -> Array:
    var resolved := _resolve_target(char_, type_name)
    var node_ID = _format_character(resolved[0], type, resolved[1], action)
    if message != null:
        return send(node_ID, message)
    return send(node_ID, resolved[0])

## 角色域通用监听：解析目标 → 拼 ID → 登记；名字带 @identity 时记为"身份接收器"，
## 以后该 identity 换角色会自动迁到新节点（见 MsgBus.bind_identity_receiver）。
## once 为 true 时登记为**一次性接收器**（广播一次后自动移除，见 MsgBus.listen / send）。
## 被谁用：本文件里角色域的所有 listen_*。
static func _listen_character(char_: Character, type: String, type_name: String, action: String, callback: Callable, once: bool = false) -> String:
    var resolved := _resolve_target(char_, type_name)
    var node_ID = _format_character(resolved[0], type, resolved[1], action)
    # 含 @identity 的监听记为"身份接收器"：照常广播，但 identity 换角色时会被迁到新节点。
    # 这样 identity 未出现时先监听也有效（等它出现时迁到正确节点）。
    var identity_bound: bool = "@" in type_name
    var msg_ID := listen(node_ID, callback, identity_bound, once)
    if identity_bound:
        var parts := type_name.split("@")
        var pure_name: String = parts[0]
        var identity: String = parts[1]
        # 工厂：identity 换角色时按新角色算出该监听应处的节点 ID
        var factory := func(new_char: Character) -> String:
            return _format_character(new_char, type, pure_name, action)
        bind_identity_receiver(identity, node_ID, callback, factory)
    return msg_ID

## 角色域"取上次消息"：同样的 ID 规则，返回该节点最近一次收到的消息。
## 被谁用：需要读"某条角色消息最近内容"的地方（如状态取上一次的 target）。
static func _get_message_character(char_: Character, type: String, type_name: String, action: String) -> Variant:
    var resolved := _resolve_target(char_, type_name)
    var node_ID = _format_character(resolved[0], type, resolved[1], action)
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
## 属性域：ID 用 ["CHAR", 角色, "ATTR"/"ANY_ATTR", 属性名, "changed"]，见 _format_character。
## 被谁用：Attributes._set_（值变化时 send）；StatusPreset 的属性监听（listen_attr_changed / listen_any_attr_changed）。
""" ---------- Attributes ---------- """
static func send_attr_changed(char_: Character, type_name: String) -> Array:
    send_any_attr_changed(char_, type_name)
    return _send_character(char_, "ATTR", type_name, "changed")

static func send_any_attr_changed(char_: Character, type_name: String) -> Array:
    return _send_character(char_, "ANY_ATTR", "ANY", "changed", type_name)

static func listen_attr_changed(char_: Character, type_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "ATTR", type_name, "changed", callback, once)

static func listen_any_attr_changed(char_: Character, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "ANY_ATTR", "ANY", "changed", callback, once)


"""
                ░████████                  ░████     ░████ 
                ░██    ░██                ░██       ░██    
                ░██    ░██  ░██    ░██ ░████████ ░████████ 
░██████ ░██████ ░████████   ░██    ░██    ░██       ░██    
                ░██     ░██ ░██    ░██    ░██       ░██    
                ░██     ░██ ░██   ░███    ░██       ░██    
                ░█████████   ░█████░██    ░██       ░██                                                         
"""
## buff 域：ID = ["CHAR", 角色, "BUFF", buff 名, 动作]。
## 被谁用：Attributes.add_buff/remove_buff 与 BuffPreset.consume（send）；
##          StatusPreset 的 buff 监听（listen_buff_add / listen_buff_remove）。
""" ---------- BuffPreset ---------- """
static func send_buff_add(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "add")

static func send_buff_remove(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "remove")

static func send_buff_consume(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "consume")

static func send_buff_depleted(char_: Character, buff_name: String) -> Array:
    return _send_character(char_, "BUFF", buff_name, "depleted")

static func listen_buff_add(char_: Character, buff_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "BUFF", buff_name, "add", callback, once)

static func listen_buff_remove(char_: Character, buff_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "BUFF", buff_name, "remove", callback, once)

static func listen_buff_consume(char_: Character, buff_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "BUFF", buff_name, "consume", callback, once)

static func listen_buff_depleted(char_: Character, buff_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "BUFF", buff_name, "depleted", callback, once)


"""
                  ░██████      ░██                  ░██                          
                 ░██   ░██     ░██                  ░██                          
                ░██         ░████████  ░██████   ░████████ ░██    ░██  ░███████  
░██████ ░██████  ░████████     ░██          ░██     ░██    ░██    ░██ ░██        
                        ░██    ░██     ░███████     ░██    ░██    ░██  ░███████  
                 ░██   ░██     ░██    ░██   ░██     ░██    ░██   ░███        ░██ 
                  ░██████       ░████  ░█████░██     ░████  ░█████░██  ░███████                                                                             
"""

## 状态域：ID = ["CHAR", 角色, "STATUS", 状态名, 动作]；satisfied/unsatisfied 是状态的主输出，
## 交互、技能、快捷、UI 都靠它。
## 被谁用：StatusPreset.execute（send_status_satisfied / unsatisfied）、Statuses.add/remove_status、
##          Msg.send_status_detected（外部检测）；listen 侧见 StatusPreset 与 InteractionPreset。
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

static func listen_status_satisfied(char_: Character, status_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "STATUS", status_name, "satisfied", callback, once)

static func listen_status_unsatisfied(char_: Character, status_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "STATUS", status_name, "unsatisfied", callback, once)

static func listen_status_add(char_: Character, status_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "STATUS", status_name, "add", callback, once)

static func listen_status_remove(char_: Character, status_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "STATUS", status_name, "remove", callback, once)

static func listen_status_detected(char_: Character, status_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "STATUS", status_name, "detected", callback, once)

## 我觉得这玩意用不到
# static func listen_status_undetected(char_: Character, status_name: String, callback: Callable) -> String:
#     return _listen_character(char_, "STATUS", status_name, "undetected", callback)

static func get_status_detected(char_: Character, status_name: String) -> Variant:
    return _get_message_character(char_, "STATUS", status_name, "detected")

## 我觉得这玩意用不到
static func get_status_undetected(char_: Character, status_name: String) -> Variant:
    return _get_message_character(char_, "STATUS", status_name, "undetected")


## 行为域：**当前未启用**（Character.behaviors 已注释，见 Character._init_from_archetype），
## 保留只为以后复用同一套 send/listen 模板。
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
## 交互域：ID = ["CHAR", 角色, "INTERACTION", 交互名, 动作]。
## 被谁用：Interactions.add/remove_interaction（增删）、InteractionPreset.listen 的触发（send_interaction_act）；
##          listen 侧是 StatusPreset 的交互监听与 InteractionPreset。
""" ---------- Character InteractionPreset ---------- """
static func send_interaction_add(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "add")

static func send_interaction_remove(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "remove")
    
static func send_interaction_act(char_: Character, interaction_name: String) -> Array:
    return _send_character(char_, "INTERACTION", interaction_name, "act")
    
static func listen_interaction_add(char_: Character, interaction_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "add", callback, once)

static func listen_interaction_remove(char_: Character, interaction_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "remove", callback, once)

static func listen_interaction_act(char_: Character, interaction_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "INTERACTION", interaction_name, "act", callback, once)


"""
                  ░██████   ░██          ░██   ░██    ░██ 
                 ░██   ░██  ░██                ░██    ░██ 
                ░██         ░██    ░██   ░██   ░██    ░██ 
░██████ ░██████  ░████████  ░██   ░██    ░██   ░██    ░██ 
                        ░██ ░███████     ░██   ░██    ░██ 
                 ░██   ░██  ░██   ░██    ░██   ░██    ░██ 
                  ░██████   ░██    ░██   ░██   ░██    ░██ 
                                                          
                                                          
"""
## 技能域：ID = ["CHAR", 角色, "SKILL", 技能名, 动作]。
## 被谁用：Skills.add/remove_skill（增删）、SkillBase.act（send_skill_act，每帧生效时）。
""" ---------- Character Skills ---------- """
static func send_skill_add(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "add")

static func send_skill_remove(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "remove")

static func send_skill_act(char_: Character, skill_name: String) -> Array:
    return _send_character(char_, "SKILL", skill_name, "act")

static func listen_skill_add(char_: Character, skill_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SKILL", skill_name, "add", callback, once)

static func listen_skill_remove(char_: Character, skill_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SKILL", skill_name, "remove", callback, once)

static func listen_skill_act(char_: Character, skill_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SKILL", skill_name, "act", callback, once)


"""
                  ░██████             ░██ ░██ ░██           ░██                      
                 ░██   ░██            ░██ ░██                                        
                ░██         ░███████  ░██ ░██ ░██ ░███████  ░██ ░███████  ░████████  
░██████ ░██████ ░██        ░██    ░██ ░██ ░██ ░██░██        ░██░██    ░██ ░██    ░██ 
                ░██        ░██    ░██ ░██ ░██ ░██ ░███████  ░██░██    ░██ ░██    ░██ 
                 ░██   ░██ ░██    ░██ ░██ ░██ ░██       ░██ ░██░██    ░██ ░██    ░██ 
                  ░██████   ░███████  ░██ ░██ ░██ ░███████  ░██ ░███████  ░██    ░██                                                                                 
"""

## 碰撞域：ID = ["CHAR", 角色, "COLLISION", 碰撞区名, 动作]（enter/exit 由 Area2D 信号驱动）。
## 被谁用：Collisions.add/remove_collision、Collision_Area 的进出回调；listen 侧见状态层的 Detect。
""" ---------- Character CollisionPreset ---------- """
static func send_collision_add(char_: Character, collision_name: String) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "add")

static func send_collision_remove(char_: Character, collision_name: String) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "remove")

static func send_collision_enter(char_: Character, collision_name: String, body: Node) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "enter", body)

static func send_collision_exit(char_: Character, collision_name: String, body: Node) -> Array:
    return _send_character(char_, "COLLISION", collision_name, "exit", body)

static func listen_collision_add(char_: Character, collision_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "add", callback, once)

static func listen_collision_remove(char_: Character, collision_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "remove", callback, once)

static func listen_collision_enter(char_: Character, collision_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "enter", callback, once)

static func listen_collision_exit(char_: Character, collision_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "COLLISION", collision_name, "exit", callback, once)


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
## 背包域：ID = ["CHAR", 角色, "INVENTORY", 背包名, 动作]。
## 被谁用：Inventories.add/remove_inventory；交互（吃/掉落/搜寻）从背包取内容时也会发。
""" ---------- Character Inventory ---------- """
static func send_inventory_add(char_: Character, inventory_name: String) -> Array:
    return _send_character(char_, "INVENTORY", inventory_name, "add")

static func send_inventory_remove(char_: Character, inventory_name: String) -> Array:
    return _send_character(char_, "INVENTORY", inventory_name, "remove")


static func listen_inventory_add(char_: Character, inventory_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "INVENTORY", inventory_name, "add", callback, once)

static func listen_inventory_remove(char_: Character, inventory_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "INVENTORY", inventory_name, "remove", callback, once)


## 快捷域：ID = ["CHAR", 角色, "SHORTCUT", 快捷名, 动作]。
## 被谁用：SystemShortcuts.add/remove_shortcut、SystemShortcutPreset.listen 的触发；
##          这是"配置驱动"的主力——UI 开菜单、按键绑指令都靠它转发到 CmdSys。
""" ---------- Character SystemShortcut ---------- """
static func send_shortcut_add(char_: Character, shortcut_name: String) -> Array:
    return _send_character(char_, "SHORTCUT", shortcut_name, "add")

static func send_shortcut_remove(char_: Character, shortcut_name: String) -> Array:
    return _send_character(char_, "SHORTCUT", shortcut_name, "remove")

static func send_shortcut_act(char_: Character, shortcut_name: String) -> Array:
    return _send_character(char_, "SHORTCUT", shortcut_name, "act")

static func listen_shortcut_add(char_: Character, shortcut_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SHORTCUT", shortcut_name, "add", callback, once)

static func listen_shortcut_remove(char_: Character, shortcut_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SHORTCUT", shortcut_name, "remove", callback, once)

static func listen_shortcut_act(char_: Character, shortcut_name: String, callback: Callable, once: bool = false) -> String:
    return _listen_character(char_, "SHORTCUT", shortcut_name, "act", callback, once)

"""
░██     ░██ ░██████
░██     ░██   ░██  
░██     ░██   ░██  
░██     ░██   ░██  
░██     ░██   ░██  
 ░██   ░██    ░██  
  ░██████   ░██████
"""
""" ---------- Basic ---------- """
static func _format_ui(ui: UIBase, action: String) -> String:
    return format_ID(["UI", RegSys.name_of(ui), action])     # UI 节点也按注册名（`UI/MiniHUD`）

static func _send_ui(ui: UIBase, action: String, message: Variant = null) -> Array:
    var node_ID: String = _format_ui(ui, action)
    if message != null:
        return send(node_ID, message)
    return send(node_ID, ui)

static func _listen_ui(ui: UIBase, action: String, callback: Callable, once: bool = false) -> String:
    return listen(_format_ui(ui, action), callback, false, once)

## UI 生命周期域（与上面的 Character 域不同，这里以**UI 实例**为 ID 段）。
## 被谁用：UIInteract_OpenClose._build_open（send_ui_create）、UIInteract_OpenClose.close（send_ui_close）。
## 注意：**send_ui_remove 当前没有任何发送方**——UI 关闭是 hide 复用，项目里已没有"销毁 UI"的路径；
## 保留它是为了以后真要销毁时（那时记得同时把 listen_ui_remove 的接收方也接上）。
""" ---------- Life Cycle ---------- """
static func send_ui_create(ui: UIBase) -> Array:
    return super.send("UI_CREATE", ui)

static func send_ui_remove(ui: UIBase) -> Array:
    return super.send("UI_REMOVE", ui)

static func listen_ui_create(callback: Callable, once: bool = false) -> String:
    return super.listen("UI_CREATE", callback, false, once)

static func listen_ui_remove(callback: Callable, once: bool = false) -> String:
    return super.listen("UI_REMOVE", callback, false, once)

## UI 交互域：fade / scale / submit 等"对 UI 做了什么"的消息。
## 被谁用：UIInteract（fade_to 等指令）、需要监听 UI 交互的外部逻辑。
""" ---------- Interact ---------- """
static func send_ui_press(ui: UIBase) -> Array:
    return _send_ui(ui, "PRESS")

static func send_ui_drag(ui: UIBase) -> Array:
    return _send_ui(ui, "DRAG")

static func send_ui_release(ui: UIBase) -> Array:
    return _send_ui(ui, "RELEASE")

static func send_ui_submit(ui: UIBase) -> Array:
    return _send_ui(ui, "SUBMIT")

static func send_ui_close(ui: UIBase) -> Array:
    return _send_ui(ui, "CLOSE")

static func send_ui_scale(ui: UIBase) -> Array:
    return _send_ui(ui, "SCALE")

static func send_ui_fade(ui: UIBase, target: float) -> Array:
    return _send_ui(ui, "FADE", target)

static func listen_ui_press(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "PRESS", callback, once)

static func listen_ui_drag(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "DRAG", callback, once)

static func listen_ui_release(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "RELEASE", callback, once)

static func listen_ui_submit(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "SUBMIT", callback, once)

static func listen_ui_close(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "CLOSE", callback, once)

static func listen_ui_scale(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "SCALE", callback, once)

static func listen_ui_fade(ui: UIBase, callback: Callable, once: bool = false) -> String:
    return _listen_ui(ui, "FADE", callback, once)
