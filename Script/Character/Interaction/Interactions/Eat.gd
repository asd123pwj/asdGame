class_name Eat
extends InteractionBase


func _init():
    pass

func interact(actor: Character, target: Character, _config: Variant) -> Enums.Code:
    
    if target.statuses.check_satisfied("Healable"):
        # 注意actor与target调换，因为actor吃target后，是target治疗actor
        return MsgHubChar.send_status_detected(target, "Detect=>Healable", actor)
    return Enums.Code.NOT_FOUND