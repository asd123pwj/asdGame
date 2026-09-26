# Status · 子文件夹总结

## 定位
"状态系统"：把一个或多个**条件(监听器)**监听的结果汇总成一个布尔状态 `satisfied`。Status 的实际用法是**监听**——它是全系统的事件判断源，被 Skill/Interaction 依赖触发。

## 文件
| 文件 | 作用 |
|---|---|
| `StatusPreset.gd` | 一条状态的预设定义(含各类监听器)。`extends PresetRegister`。 |
| `Statuses.gd` | 每个角色的状态集合。`extends BaseClass`。 |
| `StatusListener.gd`（.uid） | 监听器 `ListenType` 的描述(单条匹配规则)，见下。 |

## StatusPreset.gd 说明（Preset）
- 字段：`name/auto_reset(变化后自动复位)/match_any(任一满足即满足)/with_detect_transient(瞬时外部检测)/with_detect_manual(保持型外部检测，手动开关)` + 6 类监听器数组(attrs/buffs/statuses/interactions/keys/time)。
- 监听器 `ListenType` = `match_type(比较符) + name(监听对象) + thres(阈值)`。attrs 支持 Changed/>/</Base*/AnyChanged 等；buffs Present/Absent；statuses Satisfied/Unsatisfied；interactions Present/Absent/Act；keys 按 HOLD(按住)/PRESS(按下瞬间)/RELEASE(抬起)；time 时间推进；with_detect_transient / with_detect_manual 接受外部检测信号（瞬时亮一下 / 手动开与关）。
- **`状态名@identity` 定向语法**：监听对象名（statuses 的 `name`）若写成 `状态名@identity`，则监听的是 `CharSys.identities[identity]` 那个独特角色的状态，而非当前角色自己。解析由 `Msg._resolve_target(char_, status_name)` 统一负责（STATUS/BUFF/ATTR/... 全域通用），返回 `[目标角色, 纯状态名]`；解析失败（无该 identity 角色）则回退为 `char_` + 原名，并由 `Msg._listen_character` 把该监听登记为"绑定 identity 的接收器"，等 `bind_identity` 时迁移到正确节点（先监听、后出现也能生效）。`StatusPreset.listen` 用它同时解析"初始值读取"和"监听注册"，两者保持一致。由此多个角色可共享监听同一个"敌人/目标"角色的状态。
- `listen(char_)`：按监听器类型 `Msg.listen_*` 注册触发器，实时把各触发器真值写进 `_xxx_triggers[char_]`（本地记录仍归 `char_`；`@` 语法的"监听源/取值"转为目标角色）。
- `execute(char_, force)`：汇总各触发器真值(按 match_any 取与/或) → 得 `satisfied`；满足/解除时发 `Msg.send_status_satisfied/unsatisfied`。
- `_set_trigger(char_, triggers, 依赖名, 值)`：**写触发值的唯一入口**（各监听回调都走它，共 25 处）——
  值真的变了才写，并广播一条**"依赖变化"消息** `Msg.send_status_trigger_changed(char_, 状态名, 依赖名, 新值)`。
  **为什么必须有它**：依赖变了往往**不改 satisfied**（只按 Shift、没按回车 ⇒ `Submit` 仍不满足）⇒ 只听
  `satisfied / unsatisfied` 根本收不到 ⇒ "看状态的 UI"里那一段一直是旧值（实测现象）。
  消息节点按**状态名**分（一条状态一个节点）：订阅一次就能收到它下面**任何**依赖的变化；
  依赖名对**按键**那组是键码（int），其余组是字符串。
- `char_init_done(char_)`：初始化完成后强制 `execute` 一次，校准初始状态。
- `get_latest_message`：返回最近一次触发收到的消息(供交互取 target)。
- 供谁调用：**被 SkillPreset / InteractionPreset 监听**某状态满足/解除来触发自身行为；也供 `Interaction` 里判断(如 check_satisfied("Healable"))。

## Statuses.gd 说明（集合）
- `_init(me, status_names[])`：按名字 `add_status` 把状态装给角色。
- `add/remove_status`：装/卸状态(内部调 preset.listen/unlisten)，广播 add/remove。
- `check_satisfied(name)`：查该状态当前是否满足。
- `check_exist(name)`：是否已安装。
- `get_latest_message(name)`：取该状态最近消息。

## 角色状态一览（UI，只读 + 实时）
- 看的是"**某个角色**现在装了哪些状态、每个状态依赖什么、现在触发成什么样"：
  `Config/UI/UIPreset_View.gd` 那张表里的 `Status` 一行（六个一览共用的外壳）+ `Script/UI/UI/UI_Status.gd`（内容元素，底座 `UI_View`）。
- 它在**角色数据看板**的左上那格（`UIInteract.open(preset_name="RoleData")`），默认看 `@Char/SYS`；
  换人：`UIInteract.open(preset_name="RoleData", content_cmd="@Char/人类")` 再点各格 `[刷新]`
  （`content_cmd` 写在看板上 ⇒ 六格一起换；`content_cmd` 优先于 `char`）。
- 每个状态一段、**默认收起**；标题就写着满足情况（`✔ 满足 / ✘ 未满足` + 依赖条数），
  展开才建那一行行（折叠交互的 `items` 按需建）：满足 / 最近消息 / `auto_reset·match_any·外部检测` /
  六组依赖（`属性·Buff·状态·交互·按键·时间`）逐条"声明 → 触发真值"（真标绿、假标灰）/ 两种外部检测各一条（瞬时 / 保持型）。
- **为什么必须专门一个元素**：状态是**静态预设**（一个状态全项目一份，`_x_listeners` 是声明、
  `_x_triggers` / `satisfied` / `latest_message` 是**按角色**存的）⇒ 声明从预设读，现状一律取
  `…_triggers[角色]` 那一份；只读预设会把所有角色混在一起。
- **实时**：每个状态订四~六条（见 `UI_Status._subscribe`）——`satisfied` / `unsatisfied`（**汇总结果**变了）+
  **`trigger_changed`**（`Msg.listen_status_trigger_changed`：段里那些"依赖 → 触发真值"的行靠它，**这条不能省**，
  因为依赖变了往往不改 satisfied）+ 两种外部检测（按预设声明 `with_detect_*` 订）；
  收到就**只重铺那一段**（别的段不动、展开态照旧）⇒ 标题的 ✔/✘ 与段里的行跟着变。
- **监听的生命周期 = 开着就一直听，关掉就全退**（同 `AutoSys.run_until_unsatisfied` 那种"不需要了就自己删登记"的思路）：
  面板被打开（`UIBase.on_shown`，**新建与复用两条路都通知**）⇒ 订上被看角色的**所有**状态
  （**不看段展开没展开**——收起的段标题上也写着 ✔/✘，它照样要是实时值）；
  面板被关掉（`UIBase.on_hidden`）⇒ 全退订。`sync_listening()` 幂等，`[刷新]` / 换角色时也会重算。
  于是"开着的时候精确、关掉之后干净"。
- 这两个回调是 **UIBase 新加的一对通用钩子**（`on_shown` / `on_hidden`，由 `UIInteract.open` / `close`
  经 `UIBase.dispatch_shown / dispatch_hidden` 递归通知整棵子树）——因为"重开一个已存在的 UI"是**复用 + 显示、不发消息**，
  只靠 `listen_ui_close` 那种消息盖不到这一半。
