# Character 角色系统 · 功能联系总结

## 总体组织范式（贯穿全目录）

每个子系统都由**三层** + **一个聚合根**构成，范式高度统一：

1. **Preset 配置类**（`extends PresetRegister`）：一条配置的定义，数据实际存放在 `Config/Character/` 下同名前缀的 `*.gd`（extends ConfigBase，`values` 数组批量填充）。含 `static _we[name]` 注册表 + `static get_(name)`。
2. **集合管理类**（每角色一份，`extends BaseClass`，构造 `_init(me, 预设名数组[])`）：按预设名把能力"装到角色身上"，暴露 `add_/remove_/check_`。
3. **XXBase + 具体实现**：能通用的放 Base，具体行为由各实现类覆写接口。
4. **聚合根 `Character`**：持所有集合，从 `Archetype` 一次性组装。

所有跨模块联动走 **`Msg` 消息总线**解耦；所有实例均 `extends BaseClass`（带 `ID`）。

## 一级子文件夹/根文件职责与衔接

### `Character.gd`（聚合根，不在子文件夹）
- 一个角色实例的容器，持 `attrs/statuses/interactions/skills/collisions/inventories/shortcuts/body`。
- `_init(archetype_type, name, unique_name)`：查 `Archetype.get_()` → 按其配置数组依次 new 各集合类；**不建 body**。`unique_name` 非空时把自己登记进 `CharSys.unique`（供状态名 `@unique_name` 定向）。
- `body` **延后生成**：`ensure_body()` 首次需要时按 `archetype.bodies[0]` 建 body，未配 `bodies` 的角色留空(`null`)。"需要"点 = 进入世界(`CharSys.spawn`)、技能驱动(`Skills.physics_process`)；body 生成时会顺带 `collisions.attach_collisions()` 补挂已装碰撞区。
- 供外调用：`physics_process`(转发给 skills)、`ensure_body`、`Character.get_(id)`(查角色)。

### `CharacterSystem.gd`（`CharSys`，角色系统门面/工厂）
- `static spawn(race_name, name, unique_name)`：`create_char` 建角色 → `ensure_body()`(配了 bodies 才有) → 广播 `Msg.send_spawn`；`create_char` 只建角色逻辑，不建 body。
- `static unique: Dictionary[String, Character]` + `bind_unique(unique_name, char_)` / `get_by_unique(unique_name)`：**独特角色字典**，把 "敌人"、"目标" 等名字指向具体角色实例。绑定时机：`Character._init` 时 `unique_name` 非空则自动绑定；也可运行时调 `bind_unique` 动态改指向（如遇见新敌人时把 "敌人" 指向新角色）。
- `_physics_process(delta)`：遍历所有角色驱动 `physics_process`（帧入口，被 `Sys` 调）。
- 衔接：依赖 `Character`（生产）；是 `InventoryBase` 补货/`Interaction` 生成新角色的入口；`unique` 被 `Msg`/`StatusPreset` 的状态名 `@unique_name` 语法解析。

### `Archetype/`（种族=各模块预设名的组合根）
- 存某"种族/角色定义"用了哪些 buffs/statuses/interactions/skills/collisions/inventories/shortcuts/bodies（都是**预设名数组**，各数组都可为空）。
- `get_(name)` 支持 packages 递归展开 + 去重。
- 衔接：`Character._init_from_archetype` 只读它，是整棵系统的**唯一装配来源**；`bodies` 为空表示该角色**无 body**(纯逻辑角色，如持有按键状态的 sys 角色)。

### `Attribute/`（属性 = Buff 对属性的加成）
- `BuffPreset`(Preset)：一条加成定义(category/value_type/value/method/max_uses)，`consume`/`apply` 改值。
- `Attributes`(集合)：持该角色所有 buffs 与计算出的属性值；`add/remove_buff`、`init_attribute`、`get_`、`set_level_cur`、`consume_buffs`。
- 衔接：被 `InteractionBase.impact/attack/heal` 改值；被 `StatusPreset` 监听属性变化；变化时发 `Msg.send_attr_changed`。

### `Status/`（状态 = 条件监听，Boolean）
- `StatusPreset`(Preset)：一条状态定义(监听哪些 attrs/buffs/statuses/interactions/keys/time + 匹配规则)，`listen/unlisten` 装监听，满足时算 `satisfied`。
- `Statuses`(集合)：`add/remove_status`、`check_satisfied`、`get_latest_message`。
- 衔接：是**核心信号源**——`SkillPreset`/`InteractionPreset` 都监听"某状态 satisfied/unsatisfied"来触发自身。

### `Skill/`（技能 = 每物理帧被驱动的行为）
- `SkillPreset`(Preset)：绑定一个 `Skill_xxx` 实现 + config + 依赖状态。监听该状态 satisfied→`skill.in_queue`，unsatisfied→`out_queue`。
- `Skills`(集合)：持 `skill_queue`，`physics_process` 先 `ensure_body()`，对队列里每个 skill 调 `act`，最后 `if body: body.move_and_slide()`(body 可空)。
- `Skills/SkillBase`：`act` 包装 `_act` 并广播；`_act` 由 `Skill_Walk/Gravity/Jump/Damping` 覆写（改 `body.velocity`）。
- 衔接：被 `Character.physics_process` 转发驱动；依赖 `body`、`Statuses`(触发源)、`SysCfg`(阻尼阈值等)。

### `Interaction/`（交互 = 状态满足时的动作）
- `InteractionPreset`(Preset)：绑定一个 `Interaction_xxx` 实现 + config + 依赖状态。监听该状态 satisfied→`interaction.interact`（轻量替代见 `SystemShortcut/`）。
- `Interactions`(集合)：`add/remove_interaction`、`check_exist`。
- `Interactions/InteractionBase`：提供通用属性影响逻辑 `impact/attack/heal/cost/practice`（改 `attrs`）；`interact` 由各实现覆写。
- 衔接：被 `StatusPreset` 满足触发；`Attack/Heal/Eat...` 实际改 `char.attrs`；`DropOnDeath/TryHealSelf` 读 `char.inventories`。

### `SystemShortcut/`（系统快捷 = 状态满足即执行指令）
- `SystemShortcutPreset`(Preset)：一条快捷 = `name / dependence_status(依赖状态) / config(指令串)`。
- `SystemShortcuts`(集合)：`add/remove_shortcut`、`check_exist`。
- `listen(char_)`：`Msg.listen_status_satisfied` → 满足时 `Msg.send_cmd(config)`。是 **Interaction 的轻量版**（不碰属性/背包，只执行一条 `CmdSys` 指令）。
- 衔接：依赖 `Statuses`(触发源)、`CmdSys`(指令)；详见 `SystemShortcut/SystemShortcut.md`。

### `Collision/`（碰撞检测 = Area 探测）
- `CollisionPreset`(Preset)：绑定一个碰撞实现 `Collision_Area`。
- `Collisions`(集合)：`add/remove_collision`。
- `Collisions/Collision_Area`：`attach()` 有 `me.body` 才建 Area2D 挂到 `me.body`，无 body 则跳过；进出发 `Msg.send_collision_enter/exit`。
- 衔接：`Msg.send_collision_enter` 被 `StatusPreset.with_detect`/交互等监听；`body_entered` 通过 `body.get_meta("character")` 反查角色。

### `Inventory/`（背包 = 装 Character 实例的容器）
- `InventoryPreset`(Preset)：绑定一个 `Backpack/DeadDrop` 实现 + 初始物品 config。
- `Inventories`(集合)：按"存储类型名"(Backpack/DeadDrop)持 `InventoryBase`；`get_contents/print_contents`。
- `Inventories/InventoryBase`：通用容器 `add_to_char/put_contents/put_content`；`Backpack`(活物背包)、`DeadDrop`(死亡掉落) 是它的实例化。
- 衔接：`put_content` 遇 String 会 `CharSys.spawn` 生成新角色装入；被 `Interaction_DropOnDeath/TryHealSelf` 读取。

### `Body/`（身体 = 角色可视物理实体）
- `BodyPreset`(Preset)：名字 + sprite_path。
- `create()`：按精灵建 `CharacterBody2D`（精灵+碰撞体），挂到 current_scene，设 `meta("character", self)`。
- 衔接：`Character.ensure_body` 用它建 `body`(延后、可空)；`body` 被 Skills(改 velocity)、Collision(挂 Area)、Interaction(经 meta 反查) 共用。
