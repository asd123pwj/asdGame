class_name StatusType
extends PresetRegister


var name: String
## 为true时，每次变化完后自动重置，例如受伤后，发送一次受伤通知，然后恢复为未受伤
var auto_reset: bool
var _attr_type_listeners: Array[ListenType] = []
var _attr_type_triggers: Dictionary[Character, Array] = {}
var _attr_buff_listeners: Array[ListenType] = []
var _attr_buff_triggers: Dictionary[Character, Array] = {}
var _status_listeners: Array[ListenType] = []
var _status_triggers: Dictionary[Character, Array] = {}
var _behavior_listeners: Array[ListenType] = []
var _behavior_triggers: Dictionary[Character, Array] = {}
var _init_done: Dictionary[Character, bool] = {}
var satisfied: Dictionary[Character, bool] = {}

## 仅用于unlisten时取消对应消息接收器
## {Character: {MessageID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

# static var new_: Callable
static var _we: Dictionary[String, StatusType] = {}

## @param attr_type_listener_cfgs: 支持present, absent, changed, >, >=, <, <=, ==, !=
## @param attr_buff_listener_cfgs: 支持present, absent
## @param status_listener_cfgs: 支持satisfied, unsatisfied
## @param behavior_listener_cfgs: 支持present, absent, act
## cfgs为嵌套列表[[配置1],[配置2]]
func _init(
        name: String, 
        auto_reset: bool, 
        attr_type_listener_cfgs: Array=[], 
        attr_buff_listener_cfgs: Array=[],
        status_listener_cfgs: Array=[],
        behavior_listener_cfgs: Array=[]
        ) -> void:
    _we[name] = self
    self.name = name
    self.auto_reset = auto_reset

    for cfg in attr_type_listener_cfgs:
        self._attr_type_listeners.append(ListenType.new.callv(cfg))

    for cfg in attr_buff_listener_cfgs:
        self._attr_buff_listeners.append(ListenType.new.callv(cfg))

    for cfg in status_listener_cfgs:
        self._status_listeners.append(ListenType.new.callv(cfg))

    for cfg in behavior_listener_cfgs:
        self._behavior_listeners.append(ListenType.new.callv(cfg))

static func get_(name: String) -> StatusType:
    return _we[name]

## 在Status添加后，使用listen监听角色
## 在各监听类型中，先判断触发器是否可触发，再添加监听器
func listen(char_: Character) -> void:
    var trigger_func: Callable
    var trigger_cur: bool
    var listener: ListenType
    var msg_ID: String
    _trigger_funcs[char_] = {}
    satisfied[char_] = false
    _init_done[char_] = false

    # ----- Type监听器 -----
    _attr_type_triggers[char_] = []
    for i in range(_attr_type_listeners.size()):
        trigger_cur = false
        listener = _attr_type_listeners[i]
        if listener.match_type in ["present", "absent"]:
            var isPresent: bool = listener.match_type == "present"
            # 获取当前type是否满足条件
            trigger_cur = (isPresent == char_.attr.check_attr_type(listener.name))
            # 两个叠加的监听器用于实时监控。
            # 如果match_type是present，那么在type添加/移除时触发器为真/假，absent相反
            trigger_func = func(_msg): 
                self._attr_type_triggers[char_][i] = isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
            
            trigger_func = func(_msg): 
                self._attr_type_triggers[char_][i] = !isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type == "changed":
            # 获取当前type是否满足条件
            trigger_cur = false 
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                self._attr_type_triggers[char_][i] = true
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                self._attr_type_triggers[char_][i] = false;
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in [">", ">=", "<", "<=", "==", "!="]:
            # 获取当前type是否满足条件
            if char_.attr.check_attr_type(listener.name):
                trigger_cur = listener.check(char_.attr.get_level_cur(listener.name))
            # 同样是两个监听器，上面用于监控值变化后是否满足条件，下面用于监控type被移除
            trigger_func = func(_msg): 
                var level_cur = char_.attr.get_level_cur(listener.name)
                self._attr_type_triggers[char_][i] = listener.check(level_cur)
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
            
            trigger_func = func(_msg): 
                self._attr_type_triggers[char_][i] = false;
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_type_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
        else:
            pass ## TODO: 报错
        _attr_type_triggers[char_].append(trigger_cur)

    # ----- Buff监听器 -----
    _attr_buff_triggers[char_] = []
    for i in range(_attr_buff_listeners.size()):
        trigger_cur = false
        listener = _attr_buff_listeners[i]
        if listener.match_type in ["present", "absent"]:
            var isPresent: bool = listener.match_type == "present"
            # 获取当前buff是否满足条件
            trigger_cur = (isPresent == char_.attr.check_attr_buff(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                self._attr_buff_triggers[char_][i] = isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_buff_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


            trigger_func = func(_msg): 
                self._attr_buff_triggers[char_][i] = !isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_buff_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            pass ## TODO: 报错
        _attr_buff_triggers[char_].append(trigger_cur)

    # ----- Status监听器 -----
    # 等待status初始化完成
    for i in range(_status_listeners.size()):
        var status_type = get_(_status_listeners[i].name)
        @warning_ignore("unsafe_method_access")
        while (not status_type._init_done.get(char_, false)) or (char_.status == null):
            print("等待" + char_.name + "的状态" + status_type.name + "初始化完成")
            @warning_ignore("unsafe_property_access")
            await Engine.get_main_loop().process_frame
    # 开始监听
    _status_triggers[char_] = []
    for i in range(_status_listeners.size()):
        trigger_cur = false
        listener = _status_listeners[i]
        if listener.match_type in ["satisfied", "unsatisfied"]:
            var isSatisfied: bool = listener.match_type == "satisfied"
            # 获取当前status是否满足条件
            trigger_cur = (isSatisfied == char_.status.check_satisfied(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                self._status_triggers[char_][i] = isSatisfied
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_status_satisfied(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                self._status_triggers[char_][i] = !isSatisfied
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_status_unsatisfied(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            pass ## TODO: 报错
        _status_triggers[char_].append(trigger_cur)

    # ----- Behavior监听器 -----
    _behavior_triggers[char_] = []
    for i in range(_behavior_listeners.size()):
        trigger_cur = false
        listener = _behavior_listeners[i]
        if listener.match_type in ["present", "absent"]:
            var isPresent: bool = listener.match_type == "present"
            # 获取当前behavior是否满足条件
            trigger_cur = (isPresent == char_.behavior.check_behavior(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                _behavior_triggers[char_][i] = isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_behavior_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                _behavior_triggers[char_][i] = !isPresent
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_behavior_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
    
        elif listener.match_type == "act":
            trigger_cur = false 
            # 类似attr_type的changed
            trigger_func = func(_msg): 
                self._behavior_triggers[char_][i] = true
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_behavior_act(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                self._behavior_triggers[char_][i] = false;
                _check_and_execute(char_)
            msg_ID = MsgHubChar.listen_behavior_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


        else:
            pass ## TODO: 报错
        _behavior_triggers[char_].append(trigger_cur)



    _init_done[char_] = true
    # 初始化监听器后执行一次，发送最新状态，虽然我觉得它没有用
    _check_and_execute(char_, true)

func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
    satisfied.erase(char_)
    _attr_type_triggers.erase(char_)
    _attr_buff_triggers.erase(char_)
    _status_triggers.erase(char_)
    _behavior_triggers.erase(char_)
    _init_done.erase(char_)
    

func _check_and_execute(char_: Character, force: bool = false) -> bool:
    var enabled_ori: bool = satisfied[char_]
    satisfied[char_] = true
    for isAllow in _attr_type_triggers[char_]:
        if not satisfied[char_]:
            break
        if not isAllow:
            satisfied[char_] = false
    for isAllow in _attr_buff_triggers[char_]:
        if not satisfied[char_]:
            break
        if not isAllow:
            satisfied[char_] = false
    for isAllow in _status_triggers[char_]:
        if not satisfied[char_]:
            break
        if not isAllow:
            satisfied[char_] = false
    for isAllow in _behavior_triggers[char_]:
        if not satisfied[char_]:
            break
        if not isAllow:
            satisfied[char_] = false
    
    if satisfied[char_] and (not enabled_ori or force):
        MsgHubChar.send_status_satisfied(char_, self.name)
    # unsatisfied仅对auto_reset为false的生效，例如Live不满足，意味着死亡，需要触发unsatisfied
    elif (not satisfied[char_]) and (enabled_ori or force):
        MsgHubChar.send_status_unsatisfied(char_, self.name)

    if auto_reset:
        satisfied[char_] = false

    return satisfied[char_]
