# Inventory · 子文件夹总结

## 定位
"背包/容器系统"：装东西用的容器。特点：**装的不是物品，而是 Character 实例**（物化角色即物品）；按"存储类型名"(Backpack/DeadDrop)区分存储空间。

## 文件（一层）
| 文件 | 作用 |
|---|---|
| `InventoryPreset.gd` | 一条背包预设(绑定容器类型+初始内容)。`extends PresetRegister`。 |
| `Inventories.gd` | 每个角色的背包集合(按类型持容器)。`extends PresetRegister`。 |
| `Inventories/` | 容器基类 + 具体容器类型。 |

## InventoryPreset.gd 说明（Preset）
- 一条背包 = `name/inventory_name(容器类型 class_name)/config(初始内容)`。
- `_init` 里 `_get_inventory_by_name()`：new 出 `Backpack/DeadDrop` 等容器实例。
- `static get_(name)`：查注册表。
- `listen(char_)`：`inventory.add_to_char(char_, config)` 给角色装初始内容。

## Inventories.gd 说明（集合）
- 结构：`inventories`(类型名 Backpack/DeadDrop → 容器 InventoryBase)。
- `_init(me, names[])`：按预设名 `add_inventory`；键用 **类型名** 而非配置名，使不同配置共享同一类型存储空间。
- `add/remove_inventory`、`check_inventory`。
- `get_DeadDrop()/get_Backpack()/get_contents(type)`、`print_contents(type)`：读取某容器内容。

## Inventories/ 子目录（容器）
- **`InventoryBase.gd`**：通用容器基类，按角色分 `contents[Character]`。
  - `add_to_char(me, config)`：给角色初始化空列表+装入内容。
  - `put_contents/put_content(me, item)`：装一个物品；**item 是 String 时用 `CharSys.spawn` 现场生成角色**，是 Character 则直接入。
  - `get_contents/print_contents`：读取/打印。
- **`Backpack.gd`**：活物背包(装可携带角色)。
- **`DeadDrop.gd`**：死亡掉落容器。
