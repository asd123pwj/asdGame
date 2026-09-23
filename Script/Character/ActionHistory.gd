class_name ActionHistory
extends BaseClass
## **动作流水**：键（交互名 / 技能名…）-> 每个动作"最后一次发生"的时刻。
## **为什么要有它**：这类东西跑一下就没了（交互只活一帧、技能每帧都在跑），不留痕就"看不出刚才发生过"——
## 一览那边（`UI_Interaction` / `UI_Skill`）就照它显示"最近执行"。交互与技能各持一份
## （`Interactions.history` / `Skills.history`），**实现只有这一处**——包括限流，别在调用方各写一遍。
##
## `records`：键 -> `{动作: {"clock": 现实时间(14:03:21), "text": 游戏时间(元年正月初一 子时)}}`。
## 动作名由持有方定（交互 / 技能都是 `add` / `remove` / `act`）。
## **移除也留档**：东西从集合里删了，它那一笔仍留着（不然"刚删了什么"完全查不到）。
##
## **限流**（技能每物理帧都在跑，不限流会把流水写爆、界面跟着一秒画 60 次）：
## 某个动作在 `SysCfg.history_window` 秒内超过 `SysCfg.history_window_max` 次之后，
## **每秒只记第一次**；一直这么算到它安静 `history_window` 秒，计数才复位
## ⇒ 稳定的高频动作就是**每秒恰好一笔**。
## **限流只管这一处**：调用方**照常发消息**（消息该发就发，别拿"要不要发"当限流手段——
## 那会把别的订阅方一起坑了；消息真成了瓶颈再单独优化消息）；
## 界面那边靠"显示的文本没变就不刷"自然省下绘制（流水到秒 ⇒ 一秒最多画一次）。
var records: Dictionary[String, Dictionary] = {}
## 限流用的小账本：`键 -> {动作: {"last_sec": 上次记下来的那一秒, "count": 这一"热段"里来过几次}}`。
## 不进 `records`（那是给人看的），纯内部。
var _rate: Dictionary[String, Dictionary] = {}


## 记一笔（动作：`add` / `remove` / `act`）；**返回这次到底记没记**（false = 被限流丢掉了，
## 调用方一般不用管——消息照发，只有流水没动）。
## 时间取**当下**，两份都存（**都到秒**）：
##   · `clock` = **现实墙上时钟**（`14:03:21`）——"具体时间"；
##   · `text`  = **游戏时间**（`元年正月初一 子时`，见 TimeFormat.now_text）——游戏内的"几时"。
## **先记再广播**：接收方（一览）要在收到消息时读到刚记下的这一笔，才算得对时间。
## 被谁用：Interactions / Skills 的增删、以及"跑起来"那条链（InteractionPreset.listen / SkillBase.act）。
func record(key: String, action: String) -> bool:
    var now: int = _now_sec()
    var st: Dictionary = _state(key, action)
    var last: int = int(st.get("last_sec", -1))
    var count: int = int(st.get("count", 0))
    if last < 0 or float(now - last) >= Sys.sysCfg.history_window:
        count = 0                                        # 安静够久了（或头一次）⇒ 计数复位
    if count >= Sys.sysCfg.history_window_max and now == last:
        return false                                     # 太频繁：这一秒里已经记过一次 ⇒ 丢掉这次
    st["count"] = count + 1
    st["last_sec"] = now
    var rec: Dictionary = records.get(key, {})
    rec[action] = {"clock": _clock_text(), "text": TimeFormat.now_text()}
    records[key] = rec
    return true


## 取某个键的流水（没记过给空字典，调用方按"（还没）"显示）。被谁用：两个一览的标题与流水行。
func get_rec(key: String) -> Dictionary:
    var rec: Dictionary = records.get(key, {})
    return rec


## 某个"键 + 动作"的限流小账本（没有就现建一份塞回去——Dictionary 是引用，改它即改账本）。
## 被谁用：record。
func _state(key: String, action: String) -> Dictionary:
    var per_key: Dictionary = _rate.get(key, {})
    if not per_key.has(action):
        per_key[action] = {}
        _rate[key] = per_key
    return per_key[action]


## "现在"是第几秒：用**单调时钟**（`Time.get_ticks_msec`），只参与限流的窗口计算；
## 给人看的那串时间另走 `_clock_text()`（墙上时钟）。被谁用：record。
static func _now_sec() -> int:
    return Time.get_ticks_msec() / 1000


## 现实墙上时钟的"当下"文本：`14:03:21`（本地时间，**到秒**——限流之后最快也是每秒一笔，
## 再记毫秒没意义）。被谁用：record。
static func _clock_text() -> String:
    return Time.get_time_string_from_system()
