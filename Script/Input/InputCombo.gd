class_name InputCombo
extends RefCounted


var _sequence: Array[Variant]
var _interval: float
var _last_input_msec: float = 0
var _current_index: int = 0
var _listen_ids: Array[String] = []

static var _we: Dictionary[Array, InputCombo] = {}

func _init(sequence: Array[Variant], interval: float = 400) -> void:
    _we[sequence] = self
    _sequence = sequence
    _interval = interval
    _listen()

static func add_if_not_exist(sequence: Array[Variant]) -> bool:
    if not _we.has(sequence):
        new(sequence)
        return true
    return false

func _listen() -> void:
    var listen_keys: Array[String] = []
    for i in range(_sequence.size()):
        var key_and_key_status
        if _check_checkWithFirstDown(i):
            key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.FIRST_DOWN)
            if not key_and_key_status in listen_keys:
                listen_keys.append(key_and_key_status)
                var msg_ID = MsgHubInput.listen_key_first_down(_sequence[i], _act)
                _listen_ids.append(msg_ID)
        else:
            key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.DOWN)
            if not key_and_key_status in listen_keys:
                listen_keys.append(key_and_key_status)
                var msg_ID = MsgHubInput.listen_key_down(_sequence[i], _act)
                _listen_ids.append(msg_ID)
        key_and_key_status = str(_sequence[i]) + "_" + str(Enums.KeyStatus.FIRST_UP)
        if not key_and_key_status in listen_keys:
            listen_keys.append(key_and_key_status)
            var msg_ID = MsgHubInput.listen_key_first_up(_sequence[i], _act)
            _listen_ids.append(msg_ID)

func _unlisten() -> void:
    for i in range(_listen_ids.size()):
        MsgHubInput.unlisten(_listen_ids[i], _act)
    _listen_ids.clear()

static func unlisten(sequence: Array[Variant]) -> void:
    if _we.has(sequence):
        _we[sequence]._unlisten()
        _we.erase(sequence)

func _add_input() -> void:
    _current_index += 1
    _last_input_msec = Time.get_ticks_msec()

func _clear_input() -> void:
    _current_index = 0
    _last_input_msec = 0

func _check_full() -> bool:
    return _current_index == _sequence.size() 

func _check_deadline() -> bool:
    return (Time.get_ticks_msec() - _last_input_msec) > _interval

func _check_checkWithFirstDown(index:int = INT64_MIN) -> bool:
    if index == INT64_MIN:
        index = _current_index
    if index == 0:
        if _sequence.size() == 1:
            return false
        return _sequence[index] == _sequence[index + 1]
    return _sequence[index] == _sequence[index - 1]

func _get_next_key() -> Variant:
    return _sequence[_current_index]

func _check_next_key_down(key_and_key_status) -> bool:
    if _check_checkWithFirstDown():
        return _get_next_key() == key_and_key_status[0] && key_and_key_status[1] == Enums.KeyStatus.FIRST_DOWN
    return _get_next_key() == key_and_key_status[0] && key_and_key_status[1] == Enums.KeyStatus.DOWN

func _act(key_and_key_status) -> bool:
    if _check_combo(key_and_key_status):
        if not _sequence in InputSys.keys_downing:
            InputSys.keys_downing.append(_sequence)
            MsgHubInput.send_key_first_down(_sequence)
    else:
        if key_and_key_status[1] == Enums.KeyStatus.FIRST_UP:
            if _sequence in InputSys.keys_downing:
                InputSys.keys_downing.erase(_sequence)
                MsgHubInput.send_key_first_up(_sequence)
    return false

func _check_combo(key_and_key_status):
    if _check_next_key_down(key_and_key_status):
        if _check_deadline():
            _clear_input()
            if _check_next_key_down(key_and_key_status):
                _add_input()
        else:
            _add_input()
        if _check_full():
            _clear_input()
            return true
    return false