# Message · 消息总线

## 定位
项目唯一的跨模块解耦机制：发消息(id+内容) → 广播给监听者；也用作"最近消息存取"。角色/时间/输入等一切事件都经这里传递。

## 文件
| 文件 | 作用 |
|---|---|
| `MessageNode.gd` | 单个消息节点(某 id 的 receivers 列表 + 最近 message)。 |
| `MessageBus.gd` | 底层总线(增删节点、收发消息)。 |
| `MessageHub.gd` | `class_name Msg`：门面，集中全部 send_/listen_/get_ 方法。 |

## MessageNode.gd（extends BaseClass）
- `receivers: Array[Callable]`：普通订阅表；`message: Variant`：最近一条内容。
- `identity_receivers: Array[Callable]`：**绑定到 identity 的接收器**。它和 `receivers` **一样参与广播**（`send` 两个都遍历），唯一区别是 identity 换角色时会被迁到新角色对应的节点。分两份存是为了迁移时只搬这些，不会误搬同节点上的普通监听。

## MessageBus.gd（MsgBus，extends BaseClass）
- `static _nodes: Dictionary[String, MessageNode]`（懒建）。
- `listen(id, receiver, identity_bound := false) -> id`：订阅；`identity_bound` 为 true 时记进 `identity_receivers`（同样广播、但可迁移），否则进 `receivers`。`unlisten`：顺 `_aliases` 链找到当前节点，两类接收器都尝试移除，全空则删节点；并同步清掉该 receiver 在 `_identity_bindings` 里的登记。
- `send(id, message) -> Array`：写入 message，**依次广播 `receivers` 与 `identity_receivers`**，返回各 receiver **返回值数组**。
- `get_message(id)`：取该节点最近消息(供"取上次事件目标/值")。
- `bind_identity_receiver(identity, node_id, receiver, factory)`：登记一个"绑定到 identity"的接收器（当前节点 + 工厂 `factory(char_) -> String`）。
- `rebind_identity(identity, char_)`：identity 出现/换角色时调用——对每个登记项用工厂算出新节点 ID，与当前不同则 `_move_identity_receiver` 迁移并更新登记。
- `_move_identity_receiver(old_id, new_id, receiver)`：把 receiver 从 old_id 的 `identity_receivers` 搬到 new_id 的 `identity_receivers`（旧节点空了才删），并登记 `_aliases[old_id]=new_id` 供 `unlisten` 回溯。
- `format_ID(parts)` / `parse_ID(id)`：用 `->` 拼/拆复合消息 id。
- 供谁调用：一切 `Msg.xxx` 的底层。

## MessageHub.gd（Msg，extends MsgBus）
- 把各域消息统一到一处，避免记多个类。用 ASCII 分隔便于定位。主要分块：
  - **Spawn/Destroy**：`CHAR_CREATE/SPAWN/DESTORY`。
  - **Time**：`TICK` + `ADVANCE_YEAR/MONTH/DAY/HOUR`(每个 send_/listen_)。
  - **Input**：单键 `key_status`(`key.status` → id)；`HOLD/PRESS/RELEASE`。key 为 Array(组合键) 时自动用 `InputCombo`。
  - **Command**：`send_cmd`(COMMAND)，返回"每条指令结果"的数组；单条指令取 `[0]`。
  - **Character 各域**：经 `_format_character` 生成"某角色的某类型某 action"精确 id，细分 ATTR/ANY_ATTR、BUFF(±consume/depleted)、STATUS(satisfied/unsatisfied/detected/±add/remove)、INTERACTION、SKILL、COLLISION、INVENTORY、SHORTCUT 的 ±add/remove/act/enter 等。
  - **名字定向 `名字@identity`（全域通用）**：`_send_character`/`_listen_character`/`_get_message_character` 三个统一入口都先过 `_resolve_target(char_, type_name)`——若 `type_name` 含 `@`，则从 `CharSys.get_identity(identity)` 取出目标角色，不再用传入的 `char_`；解析失败则回退 `char_` + 原名。因此 STATUS/BUFF/ATTR/INTERACTION/SKILL/COLLISION/INVENTORY 的 type_name（状态名/buff名/属性名/交互名...）都支持该语法。
  - **消息 id 的角色标识**：`_format_character` 用 `char_.identity`（未绑定则退化为 `str(ID)` 兜底，避免匿名角色 id 冲突）而非 `str(ID)`。故 `@identity` 解析后的目标角色发出的 id 恰好是 `CHAR->identity->...`，send 端无需写 `@` 即可与 listen 端天然对上；identity 换绑到新角色时，因节点名只含 identity 字符串，send/listen 两侧仍能对上，监听不丢。
  - **绑定 identity 的接收器与迁移**：`_listen_character` 里凡 `type_name` 含 `@` 的监听，都以 `listen(..., identity_bound=true)` 记入该节点的 `identity_receivers`，并调 `bind_identity_receiver(identity, node_ID, callback, factory)` 登记（`factory(char_)` 按新角色算出该监听应处的节点）。等 `CharSys.bind_identity` 时调 `MsgBus.rebind_identity`，把接收器从旧节点迁到新角色对应的节点。因此**两点都成立**：①identity 尚未出现时先去监听，等它出现即可生效；②identity 换绑到新角色后，监听自动跟到新节点的消息上，不会丢。
- 规则：`send_xxx` / `listen_xxx` / 部分 `get_xxx`(取最近)。
- 供谁调用：**全项目所有**跨模块联动（状态/技能/交互/属性/碰撞/时间/指令等触发都靠它）。
