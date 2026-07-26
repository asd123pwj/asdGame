class_name Status
extends PresetRegister


var name: String
## 为true时，每次变化完后自动重置，例如受伤后，发送一次受伤通知，然后恢复为未受伤
var auto_reset: bool
var _attr_listeners: Array[ListenType] = []
var _attr_triggers: Dictionary[Character, Array] = {}
var _buff_listeners: Array[ListenType] = []
var _buff_triggers: Dictionary[Character, Array] = {}
var _status_listeners: Array[ListenType] = []
var _status_triggers: Dictionary[Character, Dictionary] = {}
var _behavior_listeners: Array[ListenType] = []
var _behavior_triggers: Dictionary[Character, Array] = {}
var with_detect: bool
var _detect_triggers: Dictionary[Character, bool] = {}
var _init_done: Dictionary[Character, bool] = {}
var satisfied: Dictionary[Character, bool] = {}

## 仅用于unlisten时取消对应消息接收器
## {Character: {MessageID: func}}
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

# static var new_: Callable
static var _we: Dictionary[String, Status] = {}

## @param attr_type_listener_cfgs: 支持changed, over_limit, within_limit, >, >=, <, <=, ==, !=
## @param attr_buff_listener_cfgs: 支持present, absent
## @param status_listener_cfgs: 支持satisfied, unsatisfied
## @param behavior_listener_cfgs: 支持present, absent, act
## @param with_detect: 使用外部检测信号，用send_status_detected发送
## cfgs为嵌套列表[[配置1],[配置2]]
func _init(
        name: String, 
        auto_reset: bool, 
        attr_listener_cfgs: Array=[], 
        buff_listener_cfgs: Array=[],
        status_listener_cfgs: Array=[],
        behavior_listener_cfgs: Array=[],
        with_detect: bool = false,
        ) -> void:
    _we[name] = self
    self.name = name
    self.auto_reset = auto_reset

    for cfg in attr_listener_cfgs:
        self._attr_listeners.append(ListenType.new.callv(cfg))

    for cfg in buff_listener_cfgs:
        self._buff_listeners.append(ListenType.new.callv(cfg))

    for cfg in status_listener_cfgs:
        self._status_listeners.append(ListenType.new.callv(cfg))

    for cfg in behavior_listener_cfgs:
        self._behavior_listeners.append(ListenType.new.callv(cfg))

    self.with_detect = with_detect

static func get_(name: String) -> Status:
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
    _attr_triggers[char_] = []
    for i in range(_attr_listeners.size()):
        trigger_cur = false
        listener = _attr_listeners[i]

        if listener.match_type == "changed":
            # 初始未改变
            trigger_cur = false 
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                self._attr_triggers[char_][i] = true
                execute(char_)
            msg_ID = MsgHubChar.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in ["over_limit", "within_limit"]:
            # 获取当前type是否满足条件
            trigger_cur = char_.attrs.check_limitation(listener.name) == (listener.match_type == "within_limit")
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                self._attr_triggers[char_][i] = char_.attrs.check_limitation(listener.name) == (listener.match_type == "within_limit")
                execute(char_)
            msg_ID = MsgHubChar.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in [">", ">=", "<", "<=", "==", "!="]:
            # 获取当前type是否满足条件
            # if char_.attrs.check_attr_type(listener.name):
            trigger_cur = listener.check(char_.attrs.get_(listener.name))
            # 同样是两个监听器，上面用于监控值变化后是否满足条件，下面用于监控type被移除
            trigger_func = func(_msg): 
                var level_cur = char_.attrs.get_(listener.name)
                self._attr_triggers[char_][i] = listener.check(level_cur)
                execute(char_)
            msg_ID = MsgHubChar.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
            
        else:
            pass ## TODO: 报错
        _attr_triggers[char_].append(trigger_cur)

    # ----- Buff监听器 -----
    _buff_triggers[char_] = []
    for i in range(_buff_listeners.size()):
        trigger_cur = false
        listener = _buff_listeners[i]
        if listener.match_type in ["present", "absent"]:
            var isPresent: bool = listener.match_type == "present"
            # 获取当前buff是否满足条件
            trigger_cur = (isPresent == char_.attrs.check_buff(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                self._buff_triggers[char_][i] = isPresent
                execute(char_)
            msg_ID = MsgHubChar.listen_buff_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


            trigger_func = func(_msg): 
                self._buff_triggers[char_][i] = !isPresent
                execute(char_)
            msg_ID = MsgHubChar.listen_buff_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            pass ## TODO: 报错
        _buff_triggers[char_].append(trigger_cur)

    # ----- Status监听器 -----
    # 开始监听
    _status_triggers[char_] = {}
    for listener2 in _status_listeners:
        trigger_cur = false
        if listener2.match_type in ["satisfied", "unsatisfied"]:
            var isSatisfied: bool = listener2.match_type == "satisfied"
            # 获取当前status是否满足条件
            if (char_.statuses != null) and char_.statuses.check_status(listener2.name):
                trigger_cur = (isSatisfied == char_.statuses.check_satisfied(listener2.name))
            # status未初始化完成，监听该状态添加，添加后判断状态，我真聪明
            # 如果不这样，也许会导致初始状态错误
            # 另一种做法是等待初始化完成，但这样如果依赖顺序颠倒，会死锁，例如Live依赖Dead，且Live的初始化顺序在前，则Live一直等待Dead初始化完成，而Dead又排在Live后，死锁
            else:
                trigger_func = func(_msg): 
                    _status_triggers[char_][listener2.name] = (isSatisfied == get_(listener2.name).satisfied[char_])
                    execute(char_)
                msg_ID = MsgHubChar.listen_status_add(char_, listener2.name, trigger_func)
                _trigger_funcs[char_][msg_ID] = trigger_func



            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                self._status_triggers[char_][listener2.name] = isSatisfied
                execute(char_)
            msg_ID = MsgHubChar.listen_status_satisfied(char_, listener2.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                self._status_triggers[char_][listener2.name] = !isSatisfied
                execute(char_)
            msg_ID = MsgHubChar.listen_status_unsatisfied(char_, listener2.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            pass ## TODO: 报错
        _status_triggers[char_][listener2.name] = trigger_cur

    # ----- Behavior监听器 -----
    _behavior_triggers[char_] = []
    for i in range(_behavior_listeners.size()):
        trigger_cur = false
        listener = _behavior_listeners[i]
        if listener.match_type in ["present", "absent"]:
            var isPresent: bool = listener.match_type == "present"
            # 获取当前behavior是否满足条件
            trigger_cur = (isPresent == char_.behaviors.check_behavior(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                _behavior_triggers[char_][i] = isPresent
                execute(char_)
            msg_ID = MsgHubChar.listen_behavior_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                _behavior_triggers[char_][i] = !isPresent
                execute(char_)
            msg_ID = MsgHubChar.listen_behavior_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
    
        elif listener.match_type == "act":
            trigger_cur = false 
            # 类似attr_type的changed
            trigger_func = func(_msg): 
                self._behavior_triggers[char_][i] = true
                execute(char_)
            msg_ID = MsgHubChar.listen_behavior_act(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                self._behavior_triggers[char_][i] = false;
                execute(char_)
            msg_ID = MsgHubChar.listen_behavior_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


        else:
            pass ## TODO: 报错
        _behavior_triggers[char_].append(trigger_cur)

    # ----- 外部信号记录 -----
    if with_detect:
        # 外部检测信号
        trigger_func = func(_msg): 
            self._detect_triggers[char_] = true
            execute(char_)
        msg_ID = MsgHubChar.listen_status_detected(char_, name, trigger_func)
        _trigger_funcs[char_][msg_ID] = trigger_func
        # 外部检测丢失信号
        trigger_func = func(_msg):
            self._detect_triggers[char_] = false
            execute(char_)
        msg_ID = MsgHubChar.listen_status_undetected(char_, name, trigger_func)
        # 默认未启用
        _detect_triggers[char_] = false


    # ----- 监听初始化完成 -----
    _init_done[char_] = true
    # 初始化监听器后执行一次，发送最新状态，虽然我觉得它没有用
    execute(char_, true)

func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
    satisfied.erase(char_)
    _attr_triggers.erase(char_)
    _buff_triggers.erase(char_)
    _status_triggers.erase(char_)
    _behavior_triggers.erase(char_)
    _init_done.erase(char_)
    

func execute(char_: Character, force: bool = false) -> bool:
    var enabled_ori: bool = satisfied[char_]
    satisfied[char_] = true
    for isAllow in _attr_triggers[char_]:
        if not satisfied[char_]:
            break
        if not isAllow:
            satisfied[char_] = false
    for isAllow in _buff_triggers[char_]:
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
    if not _detect_triggers.get(char_, true):
        satisfied[char_] = false
    
    if satisfied[char_] and (not enabled_ori or force):
        MsgHubChar.send_status_satisfied(char_, self.name)
    # unsatisfied仅对auto_reset为false的生效，例如Live不满足，意味着死亡，需要触发unsatisfied
    elif (not satisfied[char_]) and (enabled_ori or force):
        MsgHubChar.send_status_unsatisfied(char_, self.name)

    if auto_reset:
        satisfied[char_] = false

    return satisfied[char_]
