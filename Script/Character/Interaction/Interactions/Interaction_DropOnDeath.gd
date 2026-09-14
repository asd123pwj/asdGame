class_name Interaction_DropOnDeath
extends InteractionBase
## 死亡掉落交互：死亡时把 DeadDrop 里的东西出来（当前只打印，掉落生成还没接）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_DropOnDeath"）。

## 遍历 DeadDrop 内容并处理（**占位实现**：只打印，CharSys.spawn 那行还没接）。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(me: Character, _target: Character) -> Array:
    for race in me.inventories.get_DeadDrop():
        # CharSys.spawn(race)
        print("BehaviorDropOnDeath: ", race.name)
    return [Enums.Code.OK]
