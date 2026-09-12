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
- `_init`：`_scan_all_sources()` 扫描所有**最终继承 BaseClass** 的类的非 `_` 静态方法，命令名=`类名.方法名`（`_descends_from` 递归判基类）。并 `Msg.listen_cmd` 监听。
- `execute(command_str) -> Array`：按 `\v` 拆多条；每条：若 `&` 前缀→取值(is_value)；否则查命令→按反射的签名组装参数 → `callv` 调用，返回结果列表（元素=各命令返回值，未找到为错误串）。
- 解析（含 `$`/`&` 的定位）由 `CommandParser` 的两级缓存承担，本类不再另设缓存；每次只做"查命令 + `_build_args` + `callv`"。
- `clear_cache()`：级联清 `CommandParser` 的缓存（热重载/调试）。
- 反射签名：`script.get_script_method_list()`，参数默认值取 `default_args` 末尾对齐。
- 其它：`unregister`、`_coerce`(按目标类型转参)、`_lazy_load`、`_make_arg_meta`。
- 供谁调用：被 `Msg.send_cmd`(MessageHub) 触发；UI 按钮 `cmd` 也走它。

## CommandParser.gd（extends BaseClass）
- `parse(input) -> {name, positional, named}`（含 `is_value`）。
- **编译 / 执行两段式**：`parse` 先"编译"成**计划(plan)**再做缓存，最后"执行"计划得到本次结果。
  - `_compile`：确定性部分一次性固化（`_tokenize` 切分、字面量 `_convert_literal`、**`$` 表达式的定位**）。`$` 表达式被编译成"取值计划"：
    - `$类.函数(...)` → `{kind:"func", callable, args:[...]}`（Callable 固化）
    - `$类.<成员链>` → `{kind:"member", owner, ops:[...]}`（`owner` 为类名，`ops` 为字段/下标/方法的固化序列）
    - `$@ID.<成员链>` → `{kind:"instance", id, ops:[...]}`
    - 参数同样是计划：字面量直接内联，嵌套 `$` 递归编译
  - `_run_plan` / `_run_expr` / `_run_ops`：执行计划，**只做最后一步实时取值**（属性链的下标/取值、函数的实际调用）。
- **两级解析缓存**（key = 命令原文，value = plan）：
  - **L1 热缓存**：LRU 双向链表（`_l1` + `_l1_prev`/`_l1_next`），容量 `SysCfg.cache_command_l1_capacity`(默认 256)；命中移到表头，满则表尾降级到 L2。
  - **L2 温缓存**：命中可提升回 L1。用**"时钟指针 + 时间桶"**实现 **O(1) 过期**（不再线性扫描）：`_l2_ring` 为 N 个 Dictionary 桶，N = `ceil(TTL / 周期)`（`cache_command_l2_ttl` / `cache_command_l2_period`）；`_l2_tick` 每隔一个周期把指针 `_l2_hand` 前进一格并**清空**该桶（即淘汰最旧一批）；新项写入指针的**下一格**（最新桶），故一项存活≈TTL。例：TTL=300s、周期=60s → 5 个桶，每分钟轮转一格——正是"5 个字典成队列、最后清空并挪到前面"的环形版。另有 `_l2_index`(key→桶下标) 使 L2 查询/计数也 O(1)。
  - **总量上限**：`SysCfg.cache_command_max`(默认 1024*1024) 即 `_l2_index.size()`；写入时若达上限，则**强推指针清一格**腾位，避免缓存无限膨胀。
  - `SysCfg.cache_command=false` 时完全绕过缓存，每次全量编译。
- `_tokenize`：括号内空格并入(函数整体)、顶层双引号去包裹。
- `_find_class_script` / `_class_scripts`：类名 → 脚本，懒缓存。
- `clear_cache()`：清空类脚本与两级缓存（热重载/调试）。
- 供谁调用：CmdSys.execute；以及 `$`/`&` 取值被各配置/UI 绑定复用。
- 详细语法见文件头注释。
