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
- 消息 id 常量：`msgID_advance[_year/month/day]`。
- 供谁调用：被 `Sys._process` 驱动；`advance_*`/`tick` 被其它系统监听(如状态里的 time 监听、UI 时钟)。

## TimeFormat.gd（TimeFormat，extends BaseClass）
- `static update()`：从 `Sys.timeSys` 数值算中文 `year/month/day/hour` 静态串。
- `static year_to_chinese`：年数字转中文(1→元年)。
- 内部 `_number_to_chinese`：整数 0~99999 转中文数字。
