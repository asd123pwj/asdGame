# System · 系统内核

## 定位
项目启动入口与全局基类：`Sys`(总调度)、`BaseClass`(一切类的根)、`RandSys`(随机)。`test.gd` 是启动自测脚本。

## 文件
| 文件 | 作用 |
|---|---|
| `BaseClass.gd` | 一切自定义类的基类(带唯一 ID)。 |
| `SystemManager.gd` | `class_name Sys`，启动入口 + 全局单例注册表。 |
| `RandomSystem.gd` | `RandSys`：全局随机(带 seed)。 |
| `test.gd` | 启动时的功能自测(Test)。 |

## BaseClass.gd（extends RefCounted）
- `var ID: int = get_instance_id()`：每实例唯一 ID。项目绝大多数类继承它。

## SystemManager.gd（Sys，extends Node）
- **唯一引擎回调**：`_ready`(初始化并跑 test)、`_input/_process/_physics_process`(转发给各系统，见设计文档 §八)。
- 静态单例注册表：`static var sysCfg/randSys/msgBus/shaders/timeSys/charSys/presets/inputSys/tmapSys/cmdSys/sys`。
- 静态常量目录：`USER_CONFIG_DIR="user://Config/"`、`SYS_CONFIG_DIR="res://Config/"`、`RESET`。
- `init_sub_system()`：逐个 new 上面各系统并赋给静态字段。启动顺序即各系统就绪顺序。
- 供谁调用：全项目经 `Sys.xxx` 拿系统/配置。

## RandomSystem.gd（RandSys，extends BaseClass）
- `static rand: RandomNumberGenerator`，`_init` 用 `hash(Sys.sysCfg.random_seed)` 播种。供随机处使用。

## test.gd（Test，extends BaseClass）
- 启动自测：spawn 角色、发命令、驱动 UI 等。仅调试用，非运行时必需。
