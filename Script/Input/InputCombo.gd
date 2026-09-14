class_name InputCombo
extends BaseClass
## 组合键：把"一串按键"当一个按键用（顺序 + 间隔，全按对才触发 press/release）。
## 触发时往 InputSys.keys_holding 里塞的是**整条序列**，所以状态层把同一个 Array 当键值监听即可。
## 被谁用：Msg.listen_combo（目前项目里未启用，Test 里的示例是注释掉的）。

## 组成这个组合的按键序列（如 [KEY_A, KEY_A] 表示连按两次 A）。
## 被谁用：_listen / _check_* / _act。
var _sequence: Array[Variant]
## 相邻两次按键的最大间隔（毫秒），超时即重新开始。
var _interval: float
## 上一次按键的时间戳（毫秒），配合 _interval 判超时。
var _last_input_msec: float = 0
## 已经按对到第几个（等于 _sequence.size() 即整条按完）。
var _current_index: int = 0
## 监听时拿到的消息 ID，用于 _unlisten。
var _listen_ids: Array[String] = []

## 全部组合键：序列 → 实例（同一序列只留一份）。
## 被谁用：add_if_not_exist / unlisten。
static var _we: Dictionary[Array, InputCombo] = {}

## 建一个组合键并立刻开始监听（sequence 相同的组合键不要重复建，用 add_if_not_exist）。
## 被谁用：add_if_not_exist。
func _init(sequence: Array[Variant], interval: float = 400) -> void:
    _we[sequence] = self
    _sequence = sequence
    _interval = interval
    _listen()

## 没有这个组合键才建（返回是否新建）。被谁用：外部按需登记组合键。
static func add_if_not_exist(sequence: Array[Variant]) -> bool:
    if not _we.has(sequence):
        new(sequence)
        return true
    return false

## 给序列里每个键按需要监听 PRESS/HOLD 与 RELEASE，全部转给 _act 处理。
## 被谁用：_init。
func _listen() -> void:
    var listen_keys: Array[String] = []
    for i in range(_sequence.size()):
        var key_and_key_status
        if _check_checkWithPress(i):
            key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.PRESS)
            if not key_and_key_status in listen_keys:
                listen_keys.append(key_and_key_status)
                var msg_ID = Msg.listen_key_press(_sequence[i], _act)
                _listen_ids.append(msg_ID)
        else:
            key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.HOLD)
            if not key_and_key_status in listen_keys:
                listen_keys.append(key_and_key_status)
                var msg_ID = Msg.listen_key_hold(_sequence[i], _act)
                _listen_ids.append(msg_ID)
        key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.RELEASE)
        if not key_and_key_status in listen_keys:
            listen_keys.append(key_and_key_status)
            var msg_ID = Msg.listen_key_release(_sequence[i], _act)
            _listen_ids.append(msg_ID)

## 退订自己登记的全部监听。被谁用：unlisten。
func _unlisten() -> void:
    for i in range(_listen_ids.size()):
        Msg.unlisten(_listen_ids[i], _act)
    _listen_ids.clear()

## 注销一个组合键（退订 + 从表里删）。被谁用：外部停用组合键。
static func unlisten(sequence: Array[Variant]) -> void:
    if _we.has(sequence):
        _we[sequence]._unlisten()
        _we.erase(sequence)

## 记录"又按对了一个"，并刷新时间戳。被谁用：_check_combo。
func _add_input() -> void:
    _current_index += 1
    _last_input_msec = Time.get_ticks_msec()

## 回到起点（超时或整条按完时）。被谁用：_check_combo。
func _clear_input() -> void:
    _current_index = 0
    _last_input_msec = 0

## 整条序列是否已按完。被谁用：_check_combo。
func _check_full() -> bool:
    return _current_index == _sequence.size() 

## 距上次按键是否已超时。被谁用：_check_combo。
func _check_deadline() -> bool:
    return (Time.get_ticks_msec() - _last_input_msec) > _interval

## 第 index 个键该用 PRESS 还是 HOLD 判：与前一个键相同 → PRESS（都要抬起才能再按），不同 → HOLD（按住过渡）。
## 被谁用：_listen、_check_next_key。
func _check_checkWithPress(index:int = INT64_MIN) -> bool:
    if index == INT64_MIN:
        index = _current_index
    if index == 0:
        if _sequence.size() == 1:
            return false
        return _sequence[index] == _sequence[index + 1]
    return _sequence[index] == _sequence[index - 1]

## 当前该按的那个键。被谁用：_check_next_key。
func _get_next_key() -> Variant:
    return _sequence[_current_index]

## 这次来的键是否正是"当前该按的那个键 + 该到的状态"。
## 被谁用：_check_combo。
func _check_next_key(key_and_key_status) -> bool:
    if _check_checkWithPress():
        return _get_next_key() == key_and_key_status[0] && key_and_key_status[1] == Enums.KeyStatus.PRESS
    return _get_next_key() == key_and_key_status[0] && key_and_key_status[1] == Enums.KeyStatus.HOLD

## 收到某个键的 PRESS/HOLD/RELEASE：整条按完 → 把序列当"按下的键"广播 PRESS；
## 松开时（且组合在按住表里）→ 广播 RELEASE 并从按住表移除。
## 被谁用：_listen 登记的各个 listen_key_*。
func _act(key_and_key_status) -> bool:
    if _check_combo(key_and_key_status):
        if not _sequence in InputSys.keys_holding:
            InputSys.keys_holding.append(_sequence)
            Msg.send_key_press(_sequence)
    else:
        if key_and_key_status[1] == Enums.KeyStatus.RELEASE:
            if _sequence in InputSys.keys_holding:
                InputSys.keys_holding.erase(_sequence)
                Msg.send_key_release(_sequence)
    return false

## 推进组合键状态机：连按对（含超时重置），整条按完返回 true。
## 被谁用：_act。
func _check_combo(key_and_key_status):
    if _check_next_key(key_and_key_status):
        if _check_deadline():
            _clear_input()
            if _check_next_key(key_and_key_status):
                _add_input()
        else:
            _add_input()
        if _check_full():
            _clear_input()
            return true
    return false
