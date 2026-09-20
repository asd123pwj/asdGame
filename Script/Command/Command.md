# Command · 指令系统

## 定位
把"命令字符串"解析并执行（调某类的静态方法），并可取值表达式。是"给玩家/AI 一个文本入口"的机制（后台命令、UI 按钮 cmd、调试）。

## 文件
| 文件 | 作用 |
|---|---|
| `CommandParser.gd` | 解析命令字符串/表达式。 |
| `CommandSystem.gd` | 命令分发执行（CmdSys，注册命令 + 监听 COMMAND 消息 + 执行）。 |

## CommandSystem.gd（CmdSys，extends BaseClass）
- 命令 = 调用继承 BaseClass 类的静态方法，命令名 `类名.方法名`。
- `_init`：`_scan_all_sources()` 把所有**最终继承 BaseClass** 的类的静态方法注册为命令（**`_` 开头的私有方法也注册**，有意为之）；命令名=`命令前缀.方法名`（`_descends_from` 递归判基类，前缀见 `_cmd_host`）。并 `Msg.listen_cmd` 监听。
- `execute(command_str) -> Array`：按 `\v` 拆多条（拆行走 `CommandParser.split_lines`，带缓存）；每条：**取值行**直接收下它的值，**命令行**（`类.方法(参数)`）查命令 → 按反射的签名组装参数（`_build_args`）→ `callv` 调用，返回结果列表（元素=各行的值，命令未找到为错误串）。
- 缓存分两处：解析与拆行在 `CommandParser`；命令表这边"只算一次"的是 `_all_sources()`（源表：脚本 + 命令前缀）与每命令的 `arg_index`（参数名→下标）。
- `clear_cache()`：级联清 `CommandParser` 的缓存 + 本类源表 / 已扫前缀（热重载/调试）。
- 反射签名：`script.get_script_method_list()`，参数默认值取 `default_args` 末尾对齐。
- 其它：`_lazy_load`（懒注册：只收前缀匹配的那些源，同一前缀只扫一次）、`_build_args`（"全位置参数"快路 + `arg_index` O(1) 查名）、`_coerce`（按目标类型转参；值为 null 即"没给也没默认值"时给该类型零值）、`_make_arg_meta`。
- 供谁调用：被 `Msg.send_cmd`(MessageHub) 触发；UI 按钮 `cmd` 也走它。

## CommandParser.gd（extends BaseClass）
- `parse(input) -> {is_value, name, args}`：取值行给 `{is_value:true, value}`；命令行给 `{is_value:false, name, args:[{name, value}]}`（`name` 为空 = 位置参数）。
- **编译 / 执行两段式**：`parse` 先"编译"成**计划(plan)**再做缓存，最后"执行"计划得到本次结果。
  - `_compile`：按"一行 = 一个表达式"分两种——`_split_call` 认出 `类.方法(参数)` 就是命令（参数由 `_compile_call_args` 编译），否则整行交给 `_compile_value` 当取值。
  - **`_compile_value` 是唯一的值编译**（`"字符串"` / `[数组]` / `true,false,数字` / 其余当取值表达式）：命令行参数、表达式参数、整行取值都走它 ⇒ 三处行为必然一致。取值链被编译成"取值计划"：
    - `类.函数(...)` → `{kind:"func", callable, args:[...]}`（Callable 固化）
    - `类.<成员链>` → `{kind:"member", owner, ops:[...]}`（`owner` 为类名，`ops` 为字段/下标/方法的固化序列）
    - `@ID.<成员链>` → `{kind:"instance", id, ops:[...]}`
    - 参数同样是计划：`_compile_call_args`（命令行，带 `名字=`）/ `_compile_expr_args`（表达式里，纯位置）内部都调 `_compile_value`
  - `_run_plan` / `_run_expr` / `_run_ops` / `_run_arg` / `_run_arg_plans`：执行计划，**只做最后一步实时取值**（属性链的下标/取值、函数的实际调用）；函数参数与方法参数共用 `_run_arg_plans`。
- **两级解析缓存**（key = 命令原文，value = plan）：
  - **L1 热缓存**：LRU 双向链表（`_l1` + `_l1_prev`/`_l1_next`），容量 `SysCfg.cache_command_l1_capacity`(默认 256)；命中移到表头，满则表尾降级到 L2。
  - **L2 温缓存**：命中可提升回 L1。用**"时钟指针 + 时间桶"**实现 **O(1) 过期**（不再线性扫描）：`_l2_ring` 为 N 个 Dictionary 桶，N = `ceil(TTL / 周期)`（`cache_command_l2_ttl` / `cache_command_l2_period`）；`_l2_tick` 每隔一个周期把指针 `_l2_hand` 前进一格并**清空**该桶（即淘汰最旧一批）；新项写入指针的**下一格**（最新桶），故一项存活≈TTL。例：TTL=300s、周期=60s → 5 个桶，每分钟轮转一格——正是"5 个字典成队列、最后清空并挪到前面"的环形版。另有 `_l2_index`(key→桶下标) 使 L2 查询/计数也 O(1)。
  - **总量上限**：`SysCfg.cache_command_max`(默认 1024*1024) 即 `_l2_index.size()`；写入时若达上限，则**强推指针清一格**腾位，避免缓存无限膨胀。
  - `SysCfg.cache_command=false` 时完全绕过缓存，每次全量编译。
- **另外两张小表**（key 都是配置里反复发的字符串，统一用 `_mini_cache_put` 写：受 `cache_command` 控制、超 `cache_command_max` 就整体清空）：
  - `_path_cache`：`read` / `write` 的路径 → `{head, ops}`（路径编译一次就够，不必每次重扫字符）；
  - `_line_cache`：整串指令 → 拆好的非空行（`split_lines`，UI 事件是同一条串反复发）。
- `_split_call` / `_is_call_name` / `_is_ident`：认"整行就是一个 `类.方法(…)` 调用"（配对括号必须在行尾）。`_find_top_level_assign`：认参数里的 `名字=值`（跳过可选参数用）。`_split_top_level_args`：按顶层逗号切参数。
- `read(path)` / `write(path, value)`：按路径读/写（`Utils.read`/`Utils.write`/`Utils.swap` 用它）。两者共用 `_split_path`：整条路径编译成一个表达式计划，`write` 把**最后一步**摘出来当赋值目标（前面那段交给 `_run_expr` 走 ⇒ "kind → 宿主"的分派只有一份）；空路径 / 括号不配平 ⇒ `{}`（read 给 null，write 给 false）。
- `_find_class_script` / `_class_scripts`：类名 → 脚本，懒缓存。
- `clear_cache()`：清空类脚本、两级缓存与两张小表（热重载/调试）。
- 供谁调用：CmdSys.execute；以及取值行（`self.xxx`、`Test.int1` 这类）被各配置/UI 复用。
- 详细语法见文件头注释。
