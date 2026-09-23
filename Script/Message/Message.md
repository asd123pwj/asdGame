# Message · 消息总线

## 定位
项目唯一的跨模块解耦机制：发消息(id+内容) → 广播给监听者；也用作"最近消息存取"。角色/时间/输入等一切事件都经这里传递。

## 文件
| 文件 | 作用 |
|---|---|
| `MessageNode.gd` | 单个消息节点(某 id 的四个接收器列表 + 最近 message)。 |
| `MessageBus.gd` | 底层总线(增删节点、收发消息)。 |
| `MessageHub.gd` | `class_name Msg`：门面，集中全部 send_/listen_/get_ 方法。 |

## MessageNode.gd（extends BaseClass）
- `receivers: Array[Callable]`：普通订阅表；`message: Variant`：最近一条内容。
- `identity_receivers: Array[Callable]`：**绑定到 identity 的接收器**。它和 `receivers` **一样参与广播**（`send` 都遍历），唯一区别是 identity 换角色时会被迁到新角色对应的节点。分两份存是为了迁移时只搬这些，不会误搬同节点上的普通监听。
- `once_receivers` / `once_identity_receivers`：**一次性接收器**（同上两者的临时版）。被 `send` 调用一次后**自动移除**，所以"只触发一次的收尾函数"不用自己保存监听 ID 再 unlisten。广播顺序排在普通接收器之后；回调里再注册的一次性监听留到下一次广播（不会自我循环）。

## MessageBus.gd（MsgBus，extends BaseClass）
- `static _nodes: Dictionary[String, MessageNode]`（懒建）。
- `listen(id, receiver, identity_bound := false, once := false) -> id`：订阅；`identity_bound` 为 true 时记进 `identity_receivers`（同样广播、但可迁移），否则进 `receivers`；`once` 为 true 时记进对应的**一次性**列表（广播一次后自动移除）。`unlisten`：顺 `_aliases` 链找到当前节点，**四个列表都尝试移除**，全空则删节点；并同步清掉该 receiver 在 `_identity_bindings` 里的登记。
- `send(id, message) -> Array`：写入 message，**依次广播 `receivers` → `identity_receivers` → `once_receivers` → `once_identity_receivers`**，返回各 receiver **返回值数组**。
  **遍历一律用快照**（四个列表都 `duplicate()`）：回调里可能退订 / 重订——"看某个东西的 UI"收到消息就重铺，
  重铺会整批退订再订回来（见 `UI_View.sync_listening`）⇒ 边遍历边删会**跳过**它后面的接收器（实测踩过：
  "通配事件到节点了、收件人也在，但某些订阅收不到那一次广播"）。快照语义 = 回调里新注册的留到下一次广播。
- `get_message(id)`：取该节点最近消息(供"取上次事件目标/值")。
- `bind_identity_receiver(identity, node_id, receiver, factory)`：登记一个"绑定到 identity"的接收器（当前节点 + 工厂 `factory(char_) -> String`）。
- `rebind_identity(identity, char_)`：identity 出现/换角色时调用——对每个登记项用工厂算出新节点 ID，与当前不同则 `_move_identity_receiver` 迁移并更新登记。
- `_move_identity_receiver(old_id, new_id, receiver)`：把 receiver 从 old_id 的 identity 列表搬到 new_id 的同一个列表（**一次性身份接收器也照搬**，旧节点空了才删），并登记 `_aliases[old_id]=new_id` 供 `unlisten` 回溯。
- `format_ID(parts)` / `parse_ID(id)`：用 `->` 拼/拆复合消息 id。
- 供谁调用：一切 `Msg.xxx` 的底层。

## MessageHub.gd（Msg，extends MsgBus）
- 把各域消息统一到一处，避免记多个类。用 ASCII 分隔便于定位。主要分块：
  - **Spawn/Destroy**：`CHAR_CREATE/SPAWN/DESTORY`。
  - **Time**：`TICK` + `ADVANCE_YEAR/MONTH/DAY/HOUR`(每个 send_/listen_)。
  - **Input**：单键 `key_status`(`key.status` → id)；`HOLD/PRESS/RELEASE`。key 为 Array(组合键) 时自动用 `InputCombo`。
  - **Command**：`send_cmd`(COMMAND)，返回"每条指令结果"的数组；单条指令取 `[0]`。
  - **Character 各域**：经 `_format_character` 生成"某角色的某类型某 action"精确 id，细分 ATTR/ANY_ATTR、BUFF(±consume/depleted)、STATUS(satisfied/unsatisfied/detected/±add/remove/trigger_changed)、INTERACTION、SKILL、COLLISION、INVENTORY、SHORTCUT 的 ±add/remove/act/enter 等。
  - **通配**（不关心是哪一个、只关心"变了"）：`ANY_ATTR`（属性）、`ANY_BUFF`（buff）、`ANY_INTERACTION`（交互）、`ANY_SKILL`（技能）——节点固定按"任意"分，payload = `[名字, 动作]`（动作 = add / remove / act…）。具体那条消息顺手各发一条（别在别处单独调）。**`SKILL` 的 act 是每物理帧都发的**（技能逐帧执行，消息不省；限流只做在流水 `ActionHistory` 那边）⇒ 订它的一方要自己扛住这个频率。
  - **名字定向 `名字@identity`（全域通用）**：`_send_character`/`_listen_character`/`_get_message_character` 三个统一入口都先过 `_resolve_target(char_, type_name)`——若 `type_name` 含 `@`，则从 `CharSys.get_identity(identity)` 取出目标角色，不再用传入的 `char_`；解析失败则回退 `char_` + 原名。因此 STATUS/BUFF/ATTR/INTERACTION/SKILL/COLLISION/INVENTORY 的 type_name（状态名/buff名/属性名/交互名...）都支持该语法。
  - **消息 id 的角色标识**：`_format_character` 用角色的**注册名**（`RegSys.name_of(char_)`，如 `Char/人类`）。故 `@identity` 解析后的目标角色发出的 id 恰好是 `CHAR->identity->...`，send 端无需写 `@` 即可与 listen 端天然对上；identity 换绑到新角色时，因节点名只含 identity 字符串，send/listen 两侧仍能对上，监听不丢。
  - **绑定 identity 的接收器与迁移**：`_listen_character` 里凡 `type_name` 含 `@` 的监听，都以 `listen(..., identity_bound=true)` 记入该节点的 `identity_receivers`，并调 `bind_identity_receiver(identity, node_ID, callback, factory)` 登记（`factory(char_)` 按新角色算出该监听应处的节点）。等 `CharSys.bind_identity` 时调 `MsgBus.rebind_identity`，把接收器从旧节点迁到新角色对应的节点。因此**两点都成立**：①identity 尚未出现时先去监听，等它出现即可生效；②identity 换绑到新角色后，监听自动跟到新节点的消息上，不会丢。
- 规则：`send_xxx` / `listen_xxx` / 部分 `get_xxx`(取最近)。
- **所有 `listen_xxx` 都能多传一个 `once = true`**：一次性监听，广播一次后由 `MsgBus` 自动摘掉（`UIInteract` 的"松手收尾"就是这么挂的：临时函数只触发一次，不必自己 unlisten）。
- 供谁调用：**全项目所有**跨模块联动（状态/技能/交互/属性/碰撞/时间/指令等触发都靠它）。
