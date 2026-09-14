class_name Interaction_ScanInventory
extends InteractionBase
## 扫描背包交互：**空实现占位**（还没写扫描逻辑，只返回 OK）。
## 被谁用：InteractionPreset（interaction_name = "Interaction_ScanInventory"）。

## 占位：什么都没做。
## 被谁用：InteractionPreset.listen 的触发（依赖状态满足时）。
func interact(_me: Character, _target: Character) -> Array:
    pass
    return [Enums.Code.OK]
