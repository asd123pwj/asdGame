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
- 反射签名：`script.get_script_method_list()`，参数默认值取 `default_args` 末尾对齐。
- 其它：`unregister`、`_coerce`(按目标类型转参)、`_lazy_load`、`_make_arg_meta`。
- 供谁调用：被 `Msg.send_cmd`(MessageHub) 触发；UI 按钮 `cmd` 也走它。

## CommandParser.gd（extends BaseClass）
- `parse(input) -> {name, positional, named}`（含 `is_value`）。
- `_tokenize`：括号内空格并入(函数整体)、顶层双引号去包裹。
- `_convert`：`$` 前缀表达式 / bool / int / float / 字符串(`\$`→字面 `$`)。
- 表达式求值：`_eval_expr`(静态读值/调函数) → `_try_resolve_member`(读链) / `_try_resolve_method`(调函数) / `_resolve_instance`(`$@`实例) / `_walk_chain`(通用链访问) 。
- 供谁调用：CmdSys.execute；以及 `$`/`&` 取值被各配置/UI 绑定复用。
- 详细语法见文件头注释。
