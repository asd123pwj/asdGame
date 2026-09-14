class_name Interaction_AddBuff
extends InteractionBase
## 加 buff 交互：把自己配置里的 buff 名加到目标角色身上。
## 被谁用：InteractionPreset（interaction_name = "Interaction_AddBuff"）。

## 给目标加 config 指定的 buff（config 就是 buff 名）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(user: Character, _none) -> Array:
    return [user.attrs.add_buff(config)]
    
