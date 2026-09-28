# Time · 时间系统

## 定位
游戏内时间(年/月/日/时辰)的推进与中文格式化显示。由 `Sys._process` 每帧驱动。

## 文件
| 文件 | 作用 |
|---|---|
| `TimeSystem.gd` | `TimeSys`：时间数值推进与"每过 real 周期 advance 一步"。 |
| `TimeFormat.gd` | `TimeFormat`：把数值时间格式化成中文(年/月/日/时辰)。 |

## TimeSystem.gd（TimeSys，extends BaseClass）
- 静态状态：`year/month/day/hour`(从 1 起)。
- 内部计时：`elapse`(累计秒)、`_period_accum`(距上次推进的累计)。
- `static _process(delta)`：累加时间；累计到 `Sys.sysCfg.hour_period`(秒) → `advance()`；每帧发 `Msg.send_tick`。
- `static advance()`：hour+1，满 12→day+1，满 30→month+1，满 12→year+1；`TimeFormat.update()`；分别发 `Msg.send_advance_year/month/day/hour`。
- 供谁调用：被 `Sys._process` 驱动；`advance_*`/`tick` 被其它系统监听(如状态里的 time 监听、UI 时钟)。

## 延时指令(同一个 TimeSys 里，`""" ----- 延时指令 ----- """` 那节)
- `static after(seconds, cmd, cancel_on="", char_=null)`：**过 seconds 秒执行一条指令**。
  - **同一条再次调用 = 只重置等待时间**(判同一条 = **同一串指令**)⇒ 反复登记就是"停住才执行"；
  - 登记时顺手记下"当时正在派发事件的元素"(内部字段 `from`，**不是给配置写的参数**)：**执行时靠它解析
    `@self`/`@host`**(延时执行时已经没有"当前事件"了，见 CommandParser.event_ui 那条提醒)；
    从非事件处调用也行，那时没有 `@self` 可解析，用 `@注册名` 指对象；
  - `cancel_on` = **取消条件 = 角色状态名**：订一条**一次性**的 `Msg.listen_status_satisfied(..., once=true)`，
    那条状态一满足就作废。例：`QName.pointer_move`("鼠标一动就作废"——SYS 上的**瞬时状态**，由 PointerDetect
    在派发"移动"事件之前发，见 Archetype_System；配合"同一条重置"= 停住才执行)。
  - `char_` = 取消条件看**哪个角色**的状态：**不写 = SYS 角色**(`Sys.sys_status`，系统状态都挂在它身上)；
    要看某个具体角色的状态(如"某角色受伤就作废")就传进来。拿不到角色时只**警告一句**、这条照排(不设取消条件)。
- `static cancel(cmd)`：按指令串取消那一条；`cancel_all()` = 全清。
- `_arm_cancel/_unlisten`：订 / 退那条取消监听(凭据存在条目里——**没命中却先到点的场合要主动退**，
  不然每悬停一次就留一条)；`_on_cancel_hit`：命中即摘条目。
- `_tick_delays(delta)`：`_process` 里每帧倒计时，到点**先摘掉再执行**(执行前把 元素/事件名 摆回登记时的值)。
- 用在哪：`UIPreset_Basic.tip_events` —— 悬停提示"指针停住 1 秒才弹"(每次移动重置、指针离开作废)。

## TimeFormat.gd（TimeFormat，extends BaseClass）
- `static update()`：从 `Sys.timeSys` 数值算中文 `year/month/day/hour` 静态串。
- `static year_to_chinese`：年数字转中文(1→元年)。
- 内部 `_number_to_chinese`：整数 0~99999 转中文数字。
