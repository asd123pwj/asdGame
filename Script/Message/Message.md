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
- `receivers: Array[Callable]`、`message: Variant`。就是"某消息 id 的订阅表 + 最近一条内容"。

## MessageBus.gd（MsgBus，extends BaseClass）
- `static _nodes: Dictionary[String, MessageNode]`（懒建）。
- `listen(id, receiver) -> id`：订阅；`unlisten`：退订(空则删节点)。
- `send(id, message) -> Array`：写入 message 并广播，返回各 receiver **返回值数组**。
- `get_message(id)`：取该节点最近消息(供"取上次事件目标/值")。
- `format_ID(parts)` / `parse_ID(id)`：用 `->` 拼/拆复合消息 id。
- 供谁调用：一切 `Msg.xxx` 的底层。

## MessageHub.gd（Msg，extends MsgBus）
- 把各域消息统一到一处，避免记多个类。用 ASCII 分隔便于定位。主要分块：
  - **Spawn/Destroy**：`CHAR_CREATE/SPAWN/DESTORY`。
  - **Time**：`TICK` + `ADVANCE_YEAR/MONTH/DAY/HOUR`(每个 send_/listen_)。
  - **Input**：单键 `key_status`(`key.status` → id)；`DOWN/FIRST_DOWN/FIRST_UP`。key 为 Array(组合键) 时自动用 `InputCombo`。
  - **Command**：`send_cmd`(COMMAND)；`send_cmd0` 去一层、`send_cmd00` 去两层取结果。
  - **Character 各域**：经 `_format_character` 生成"某角色的某类型某 action"精确 id，细分 ATTR/ANY_ATTR、BUFF(±consume/depleted)、STATUS(satisfied/unsatisfied/detected/±add/remove)、INTERACTION、SKILL、COLLISION、INVENTORY 的 ±add/remove/act/enter 等。
- 规则：`send_xxx` / `listen_xxx` / 部分 `get_xxx`(取最近)。
- 供谁调用：**全项目所有**跨模块联动（状态/技能/交互/属性/碰撞/时间/指令等触发都靠它）。
