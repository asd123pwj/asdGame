class_name Interaction_Attack
extends InteractionBase
## 攻击交互：攻击者用 Strength 打防御者的 Defense，结算为防御者 Health 的下降；
## 同时给双方各发一次"练习"检测（攻防都会成长）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_Attack"）。

## 执行一次攻击结算（defender 同时充当"比较对象"与"受影响者"）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(attacker: Character, defender: Character) -> Array:
    # print(attacker.name, "攻击", defender.name)

    var result = attack(attacker, defender, defender, "Strength", "Defense", "Health")
    Msg.send_status_detected_transient(attacker, "Detect=>Practice", "Strength")
    Msg.send_status_detected_transient(defender, "Detect=>Practice", "Defense")
    if (result.code == Enums.Code.OK):
        pass
    return [result]
