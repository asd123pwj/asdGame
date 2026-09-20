# AutoSys（状态驱动执行器）

`Script/Auto/AutoSystem.gd`，类名 `AutoSys`（命名与 `CharSys` / `TimeSys` / `UiSys` 一套：文件 `XxxSystem.gd`，类名短名）。

## 职责

**"某角色某状态满足期间，每帧执行一条指令"**。一条登记 = `[角色, 状态名, 指令串]`：

- 状态**满足** → 每帧把指令串交给 `Msg.send_cmd` 执行；
- 状态**不满足**（松手/结束）→ 这条登记**自动删掉**，调用方不用配对写"停止"。

所以它解决的是"按住期间一直做，但指针会离开元素"这一类交互：
等比缩放最典型（手柄必然被指针甩在身后），按 hover 派发的事件中途就断；
挂在状态上就与指针无关了。

## 用法

**登记方是代码，不是配置**——因为指令是字符串，散在代码里以后不好统一改。
所以元素配置里只写"登记入口"指令，真正交给 AutoSys 的动作在 UIInteract 里成对写好：

```gdscript
# 配置（元素自己的 events）
"events": [["Mouse Left", "UIInteract.rescale self.parent event"]]

# UIInteract 里成对的两个函数
static func rescale(target: UIBase, status_name: String) -> void:      # 登记入口
    AutoSys.run_until_unsatisfied(Sys.sys_status, status_name, rescaling.bind(ui))

static func rescaling(target: UIBase) -> void:                        # 每帧执行
    ...
```

- `event` 由 `UIBase._resolve_cmd` 换成**带引号的触发事件名**（也就是状态名 / Key 名），
  所以配置不必把状态名再抄一遍，换键位只改状态层。
- 第一个参数是**角色**：UI 里是 `Sys.sys_status`（系统状态都挂在它身上），任意角色都行。

## API

| 函数 | 作用 |
|---|---|
| `run_until_unsatisfied(char_, status_name, callback: Callable)` | 登记（同 角色+状态名+回调 只登记一次）；callback 由调用方 `bind` 好参数。名字强调"跑到不满足为止，然后销毁" |
| `stop(char_, status_name)` | 手动注销该角色该状态名下的全部登记（一般用不到） |
| `_process(delta)` | 每帧过一遍：不满足就删，满足就调回调（由 `Sys._process` 直接调，不占快捷指令） |
| `autos: Array` | 登记表，`[角色, 状态名, Callable]`（探查/调试用） |

## 谁在驱动它

`Sys._process`（`SystemManager.gd`）每帧直接调：`InputSys._process` → `TimeSys._process` → `AutoSys._process`。
所以"每帧"的定义与其它系统一致（拖拽/缩放消费的就是本帧 `mouse_delta`）。

`_process` 用**副本**遍历，因为回调里可能又登记/注销（例如一个开关换来换去）。

## 与相邻做法的取舍

- **不用 `UiSys` 存逐帧回调**：那只是"每帧跑一个 Callable"，谁在按、什么时候停都得调用方自己记着（要额外的捕获/退订机制）。挂到状态上，开始与结束都由状态层给出，调用方零负担。
- **不用 `Msg.listen_status_unsatisfied` 的一次性监听**：那也能收尾，但每次交互都要临时挂/退订一条消息监听；`_process` 每帧顺手看一眼状态更简单（`once` 仍保留在消息层，供别的场合用）。
- **不用 `"Mouse Left | Tick"` 这类逐帧状态**：① 配置里现在也没有它（`Archetype_System` 里注释着）；② 即使有，那种事件也只发给指针当前 hover 的元素——指针一离开就断。现在的"每帧"统一由本类的 `_process` 驱动（消费者：`UIInteract.rescaling` 等比缩放、`UIInteract.dragging` 按住拖动）。
- **登记用 Callable，不用指令串**：指定"每帧跑什么"如果写成指令串，那条字符串就等于把函数名散落在代码里（改函数名/统一调整时 grep 不全）。UI 侧的约定是成对写两个函数（登记入口 + 每帧执行），只有**配置**里才出现指令。
