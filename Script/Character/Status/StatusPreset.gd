class_name StatusPreset
extends PresetRegister


## 预设名（唯一，也是状态名）。被谁用：Statuses 的字典键、Msg 的状态消息、指令里的依赖名。
var name: String
## 为true时，每次变化完后自动重置，例如受伤后，发送一次受伤通知，然后恢复为未受伤
## 不建议为true的状态被监控unsatififed，
var auto_reset: bool
## 真=任一条件满足即满足；假=全部条件满足才满足（配置 match_any）。被谁用：execute。
var match_any: bool
## 以下六组：监听条件（_*_listeners，来自配置）+ 每个角色当前的触发情况（_*_triggers）。
## 被谁用：listen（登记）、execute（汇总）、unlisten（清理）。
var _attr_listeners: Array[ListenType] = []
var _attr_triggers: Dictionary[Character, Dictionary] = {}
var _buff_listeners: Array[ListenType] = []
var _buff_triggers: Dictionary[Character, Dictionary] = {}
var _status_listeners: Array[ListenType] = []
var _status_triggers: Dictionary[Character, Dictionary] = {}
var _interaction_listeners: Array[ListenType] = []
var _interaction_triggers: Dictionary[Character, Dictionary] = {}
# 有按键监听器时，auto_reset也应为true，好像没必要，首次按下和抬起都有自动重置
var _key_listeners: Array[ListenType] = []
var _key_triggers: Dictionary[Character, Dictionary] = {}
var _time_listeners: Array[ListenType] = []
var _time_triggers: Dictionary[Character, Dictionary] = {}
## 是否额外接受外部检测信号（Msg.send_status_detected）。被谁用：listen（登记）、execute（并入判定）。
var with_detect: bool
## 每个角色当前的"外部检测"触发情况。被谁用：listen、execute、unlisten。
var _detect_triggers: Dictionary[Character, bool] = {}

## 上面六组触发器字典的列表（execute 统一遍历，顺序要与上面声明一致）。
## 被谁用：execute、unlisten。
var _triggers: Array[Dictionary] = [_attr_triggers, _buff_triggers, _status_triggers, _interaction_triggers, _key_triggers, _time_triggers]

# var _init_done: Dictionary[Character, bool] = {}
## 每个角色当前是否满足。被谁用：Statuses.check_satisfied、execute、listen。
var satisfied: Dictionary[Character, bool] = {}
## 触发器触发时，记录触发器收到的消息
## 暂时我觉得它仅用于单个监听器的状态，因为多个监听器会相互覆盖消息
## 一种用法是AnyChanged记录变化的属性，然后用该状态触发SayChanged，用SayChanged打印被改变的属性
## 一种用法是with_detect记录碰撞体进入，用该状态触发Touch，然后Attack得知碰撞体消息
## 被谁用：Statuses.get_latest_message、InteractionPreset.listen（取交互对象）。
var latest_message: Dictionary[Character, Variant] = {}
## 仅用于unlisten时取消对应消息接收器
## {Character: {MessageID: func}}
## 被谁用：listen（记下）、unlisten（退订）。
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

# static var new_: Callable
## 全部预设：名 -> 实例。被谁用：StatusPreset.get_。
static var _we: Dictionary[String, StatusPreset] = {}

## attrs: 支持AnyChanged, Changed, Over Limit, Within Limit, 
    #  >,        >=,        <,        <=,        ==,        !=
    # ">Base",  ">=Base",  "<Base",  "<=Base",  "==Base",  "!=Base",
    # ">Base+", ">=Base+", "<Base+", "<=Base+", "==Base+", "!=Base+",
    # ">Base-", ">=Base-", "<Base-", "<=Base-", "==Base-", "!=Base-",
    # ">Base*", ">=Base*", "<Base*", "<=Base*", "==Base*", "!=Base*",
    # ">Base/", ">=Base/", "<Base/", "<=Base/", "==Base/", "!=Base/",
## buffs: 支持Present, Absent
## statuses: 支持Satisfied, Unsatisfied
## interactions: 支持Present, Absent, Act
## keys: 支持Enums.KeyStatus.PRESS, Enums.KeyStatus.HOLD, Enums.KeyStatus.RELEASE
##       （指针类事件不进状态层：Pointer Enter / Exit / Move 由 PointerDetect._process 直接派发给 UI）
## time: name支持Year, Month, Xun, Aay, Hour, Tick
##       condition支持Advance
## with_detect: 使用外部检测信号，用send_status_detected发送
## cfgs为嵌套列表[[配置1],[配置2]]
## 注册一条状态预设：把配置里各监听段（attrs/buffs/statuses/interactions/keys/time）解析成 ListenType 列表。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(config: Dictionary) -> void:
    name = config["name"]
    _we[name] = self
    auto_reset = Utils.find_dict(config, ["auto_reset"], false)
    match_any = Utils.find_dict(config, ["match_any"], false)
    for cfg in Utils.find_dict(config, ["attrs"], []):
        self._attr_listeners.append(ListenType.new.callv(cfg))
    for cfg in Utils.find_dict(config, ["buffs"], []):
        self._buff_listeners.append(ListenType.new.callv(cfg))
    for cfg in Utils.find_dict(config, ["statuses"], []):
        self._status_listeners.append(ListenType.new.callv(cfg))
    for cfg in Utils.find_dict(config, ["interactions"], []):
        self._interaction_listeners.append(ListenType.new.callv(cfg))
    for cfg in Utils.find_dict(config, ["keys"], []):
        self._key_listeners.append(ListenType.new.callv(cfg))
    for cfg in Utils.find_dict(config, ["time"], []):
        self._time_listeners.append(ListenType.new.callv(cfg))
    self.with_detect = Utils.find_dict(config, ["with_detect"], false)

## 按名取预设。被谁用：Statuses.add_status、本类"等某状态添加"的监听回调。
static func get_(name: String) -> StatusPreset:
    return _we[name]

## 取该角色最近一次触发时收到的消息。
## 被谁用：Statuses.get_latest_message → InteractionPreset.listen（拿交互对象）。
func get_latest_message(char_: Character) -> Variant:
    return latest_message[char_]

## 在Status添加后，使用listen监听角色
## 在各监听类型中，先判断触发器是否可触发，再添加监听器
## 逐类给该角色挂消息监听，回调里"更新触发情况 → execute() 重算"，消息 ID 记下供 unlisten。
## 被谁用：Statuses.add_status。
func listen(char_: Character) -> void:
    var trigger_func: Callable
    var trigger_cur: bool
    var msg_ID: String
    _trigger_funcs[char_] = {}
    satisfied[char_] = false

    # ----- Attribute监听器 -----
    _attr_triggers[char_] = {}
    for listener in _attr_listeners:
        trigger_cur = false

        if listener.match_type == "Changed":
            # 初始未改变
            trigger_cur = false 
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                # Changed是瞬时事件，触发后直接重置
                latest_message[char_] = _msg
                self._attr_triggers[char_][listener.name] = true
                execute(char_)
                self._attr_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in ["Over Limit", "Within Limit"]:
            # 获取当前type是否满足条件
            trigger_cur = char_.attrs.check_limitation(listener.name) == (listener.match_type == "Within Limit")
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._attr_triggers[char_][listener.name] = char_.attrs.check_limitation(listener.name) == (listener.match_type == "Within Limit")
                execute(char_)
            msg_ID = Msg.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in [">", ">=", "<", "<=", "==", "!="]:
            # 获取当前type是否满足条件
            # if char_.attrs.check_attr_type(listener.name):
            trigger_cur = listener.check(char_.attrs.get_(listener.name))
            # 同样是两个监听器，上面用于监控值变化后是否满足条件，下面用于监控type被移除
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                var level_cur = char_.attrs.get_(listener.name)
                self._attr_triggers[char_][listener.name] = listener.check(level_cur)
                execute(char_)
            msg_ID = Msg.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type in [
            ">Base", ">=Base", "<Base", "<=Base", "==Base", "!=Base",
            ">Base+", ">=Base+", "<Base+", "<=Base+", "==Base+", "!=Base+",
            ">Base-", ">=Base-", "<Base-", "<=Base-", "==Base-", "!=Base-",
            ">Base*", ">=Base*", "<Base*", "<=Base*", "==Base*", "!=Base*",
            ">Base/", ">=Base/", "<Base/", "<=Base/", "==Base/", "!=Base/",
            ]:
            # 获取当前type是否满足条件
            # if char_.attrs.check_attr_type(listener.name):
            var b = char_.attrs.get_(listener.name, Enums.ValueType.BASE)
            var cur = char_.attrs.get_(listener.name)
            @warning_ignore_start("unsafe_method_access")
            if listener.match_type.ends_with("+"):
                b += listener.thres
            elif listener.match_type.ends_with("-"):
                b -= listener.thres
            elif listener.match_type.ends_with("*"):
                b *= listener.thres
            elif listener.match_type.ends_with("/"):
                b /= listener.thres
            @warning_ignore_restore("unsafe_method_access")
            trigger_cur = listener.check(cur, b)
            # 同样是两个监听器，上面用于监控值变化后是否满足条件，下面用于监控type被移除
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                var b_ = char_.attrs.get_(listener.name, Enums.ValueType.BASE)
                var cur_ = char_.attrs.get_(listener.name)
                @warning_ignore_start("unsafe_method_access")
                if listener.match_type.ends_with("+"):
                    b_ += listener.thres
                elif listener.match_type.ends_with("-"):
                    b_ -= listener.thres
                elif listener.match_type.ends_with("*"):
                    b_ *= listener.thres
                elif listener.match_type.ends_with("/"):
                    b_ /= listener.thres
                @warning_ignore_restore("unsafe_method_access")
                self._attr_triggers[char_][listener.name] = listener.check(cur_, b_)
                execute(char_)
            msg_ID = Msg.listen_attr_changed(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
            
        elif listener.match_type == "AnyChanged":
            # 初始未改变
            trigger_cur = false 
            # 同样是两个监听器，上面用于监控值变化，下面用于监控type被移除
            trigger_func = func(_msg): 
                # AnyChanged是瞬时事件，触发后直接重置
                latest_message[char_] = _msg
                self._attr_triggers[char_][listener.name] = true
                execute(char_)
                self._attr_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_any_attr_changed(char_, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
        else:
            print("属性监听器类型错误: ", listener.match_type)  
        _attr_triggers[char_][listener.name] = trigger_cur

    # ----- Buff监听器 -----
    _buff_triggers[char_] = {}
    for listener in _buff_listeners:
        trigger_cur = false
        if listener.match_type in ["Present", "Absent"]:
            var isPresent: bool = listener.match_type == "Present"
            # 获取当前buff是否满足条件
            trigger_cur = (isPresent == char_.attrs.check_buff(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._buff_triggers[char_][listener.name] = isPresent
                execute(char_)
            msg_ID = Msg.listen_buff_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._buff_triggers[char_][listener.name] = !isPresent
                execute(char_)
            msg_ID = Msg.listen_buff_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            print("Buff监听器类型错误: ", listener.match_type)
        _buff_triggers[char_][listener.name] = trigger_cur

    # ----- Status监听器 -----
    # 开始监听
    _status_triggers[char_] = {}
    for listener in _status_listeners:
        trigger_cur = false
        if listener.match_type in ["Satisfied", "Unsatisfied"]:
            var isSatisfied: bool = listener.match_type == "Satisfied"
            # "状态名@identity" 时监听对象为 unique 角色，初始值/监听都转向它
            var resolved := Msg._resolve_target(char_, listener.name)
            var target: Character = resolved[0]
            var status_name_: String = resolved[1]
            # 获取当前status是否满足条件
            if (target != null) and (target.statuses != null) and target.statuses.check_exist(status_name_):
                trigger_cur = (isSatisfied == target.statuses.check_satisfied(status_name_))
            # status未初始化完成，监听该状态添加，添加后判断状态，我真聪明
            # 如果不这样，也许会导致初始状态错误
            # 另一种做法是等待初始化完成，但这样如果依赖顺序颠倒，会死锁，例如Live依赖Dead，且Live的初始化顺序在前，则Live一直等待Dead初始化完成，而Dead又排在Live后，死锁
            else:
                trigger_func = func(_msg): 
                    latest_message[char_] = _msg
                    _status_triggers[char_][listener.name] = (isSatisfied == get_(status_name_).satisfied.get(target, false))
                    execute(char_)
                msg_ID = Msg.listen_status_add(char_, listener.name, trigger_func)
                _trigger_funcs[char_][msg_ID] = trigger_func

            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._status_triggers[char_][listener.name] = isSatisfied
                execute(char_)
            msg_ID = Msg.listen_status_satisfied(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._status_triggers[char_][listener.name] = !isSatisfied
                execute(char_)
            msg_ID = Msg.listen_status_unsatisfied(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            print("Status监听器类型错误: ", listener.match_type)
        _status_triggers[char_][listener.name] = trigger_cur


    # ----- Interaction监听器 -----
    _interaction_triggers[char_] = {}
    for listener in _interaction_listeners:
        trigger_cur = false
        if listener.match_type in ["Present", "Absent"]:
            var isPresent: bool = listener.match_type == "Present"
            # 获取当前interaction是否满足条件
            trigger_cur = (isPresent == char_.interactions.check_exist(listener.name))
            # 两个叠加的监听器用于实时监控。
            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                _interaction_triggers[char_][listener.name] = isPresent
                execute(char_)
            msg_ID = Msg.listen_interaction_add(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                _interaction_triggers[char_][listener.name] = !isPresent
                execute(char_)
            msg_ID = Msg.listen_interaction_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
    
        elif listener.match_type == "Act":
            trigger_cur = false 
            # 类似attr_type的changed
            trigger_func = func(_msg): 
                # 瞬时事件触发后重置
                latest_message[char_] = _msg
                self._interaction_triggers[char_][listener.name] = true
                execute(char_)
                self._interaction_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_interaction_act(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

            trigger_func = func(_msg): 
                latest_message[char_] = _msg
                self._interaction_triggers[char_][listener.name] = false;
                execute(char_)
            msg_ID = Msg.listen_interaction_remove(char_, listener.name, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func


        else:
            print("Behavior监听器类型错误: ", listener.match_type)
        _interaction_triggers[char_][listener.name] = trigger_cur

    # ----- Key监听器 -----
    _key_triggers[char_] = {}
    for listener in _key_listeners:
        trigger_cur = false
        # 配置里键直接写常量（KEY_RIGHT / MOUSE_BUTTON_LEFT…），本身就是数值，无需转换
        var key_internal: Variant = listener.name
        if listener.match_type == Enums.KeyStatus.HOLD:
            # 按键为单帧触发，因此不需要监听当前按键，我猜是这样
            trigger_func = func(_msg):
                latest_message[char_] = _msg
                _key_triggers[char_][listener.name] = true
                execute(char_)
            msg_ID = Msg.listen_key_hold(key_internal, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func
            
            trigger_func = func(_msg):
                latest_message[char_] = _msg
                _key_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_key_release(key_internal, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type == Enums.KeyStatus.PRESS:
            # first down必然是瞬时事件，所以触发后直接重置
            trigger_func = func(_msg):
                latest_message[char_] = _msg
                _key_triggers[char_][listener.name] = true
                execute(char_)
                _key_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_key_press(key_internal, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        elif listener.match_type == Enums.KeyStatus.RELEASE:
            # first up必然是瞬时事件，所以触发后直接重置
            trigger_func = func(_msg):
                latest_message[char_] = _msg
                _key_triggers[char_][listener.name] = true
                execute(char_)
                _key_triggers[char_][listener.name] = false
                execute(char_)
            msg_ID = Msg.listen_key_release(key_internal, trigger_func)
            _trigger_funcs[char_][msg_ID] = trigger_func

        else:
            print("Key监听器类型错误: ", listener.match_type)
        _key_triggers[char_][listener.name] = trigger_cur

    # ----- 时间监听器 -----
    _time_triggers[char_] = {}
    for listener in _time_listeners:
        trigger_cur = false
        if listener.match_type == "Advance":
            trigger_func = func(_msg):
                # 瞬时事件触发后重置
                latest_message[char_] = _msg
                _time_triggers[char_][listener.name] = true
                execute(char_)
                _time_triggers[char_][listener.name] = false
                execute(char_)
            if listener.name == "Year":
                msg_ID = Msg.listen_advance_year(trigger_func)
            elif listener.name == "Month":
                msg_ID = Msg.listen_advance_xun(trigger_func)
            elif listener.name == "Xun":
                msg_ID = Msg.listen_advance_xun(trigger_func)
            elif listener.name == "Day":
                msg_ID = Msg.listen_advance_day(trigger_func)
            elif listener.name == "Hour":
                msg_ID = Msg.listen_advance_hour(trigger_func)
            elif listener.name == "Tick":
                msg_ID = Msg.listen_tick(trigger_func)
            else:
                print("时间监听器名称错误: ", listener.name)

            _trigger_funcs[char_][msg_ID] = trigger_func
        else:
            print("时间监听器类型错误: ", listener.match_type)
        _time_triggers[char_][listener.name] = trigger_cur
        

    # ----- 外部信号记录 -----
    if with_detect:
        # 外部检测信号
        trigger_func = func(_msg): 
            # 瞬时事件触发后重置
            latest_message[char_] = _msg
            self._detect_triggers[char_] = true
            execute(char_)
            self._detect_triggers[char_] = false
            execute(char_)
        msg_ID = Msg.listen_status_detected(char_, name, trigger_func)
        _trigger_funcs[char_][msg_ID] = trigger_func
        # 外部检测丢失信号
        # trigger_func = func(_msg):
        #     self._detect_triggers[char_] = false
        #     execute(char_)
        # msg_ID = Msg.listen_status_undetected(char_, name, trigger_func)
        # 默认未启用
        _detect_triggers[char_] = false



    # # ----- 监听初始化完成 -----
    # # 初始化监听器后执行一次，发送最新状态，虽然我觉得它没有用
    # execute(char_, true)

## 装配收尾：强制重算并广播一次，让"装配前就已满足"的状态立刻生效。
## 被谁用：Statuses.char_init_done（Character.init_done 里统一调）。
func char_init_done(char_: Character) -> void:
    execute(char_, true)

## 退订该角色的全部监听，并清掉它在各字典里的记录。
## 被谁用：Statuses.remove_status。
func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
    satisfied.erase(char_)
    latest_message.erase(char_)
    for triggers in _triggers:
        triggers.erase(char_)

## 重新汇总该角色是否满足并广播：match_any 决定"任一/全部"，with_detect 并入外部检测，
## force 用于初始化时强制广播（哪怕没变化）。返回汇总后的满足情况。
## 被谁用：listen 的各监听回调、char_init_done、需要主动重算时。
func execute(char_: Character, force: bool = false) -> bool:
    var enabled_ori: bool = satisfied[char_]
    # match_any: 任一条件满足则满足; 否则需全部满足
    satisfied[char_] = not match_any
    for triggers in _triggers:
        for key in triggers[char_]:
            if satisfied[char_] == match_any:
                break
            if triggers[char_][key] == match_any:
                satisfied[char_] = match_any
                break
    if with_detect:
        if _detect_triggers[char_] == match_any:
            satisfied[char_] = match_any
    
    if satisfied[char_] and (not enabled_ori or force):
        Msg.send_status_satisfied(char_, self.name)

    if auto_reset:
        satisfied[char_] = false
        Msg.send_status_unsatisfied(char_, self.name)
    elif (not satisfied[char_]) and (enabled_ori or force):
        Msg.send_status_unsatisfied(char_, self.name)

    return satisfied[char_]
