class_name Behavior_Grow
extends BehaviorBase


func act(me: Character, _config: Array) -> Enums.Code:
    MsgHubChar.send_status_detected(me, "Detect=>Grow", "Health")
    return Enums.Code.OK
    