class_name Enums
## 全项目统一枚举/常量表（不实例化）。
## 被谁用：几乎所有模块；凡是"多种结果/类型/策略"的取值都从这里取，不要在别处另造字符串。
## 改这里的成员名或顺序要全局搜一遍引用（尤其配置里写的是 `Enums.Xxx.Yyy` 常量名）。


## 通用结果码（沿用 HTTP 语义，OK=200、未改动=304）。
## 被谁用：Attributes/各集合的增删返值、指令结果判断。
enum Code {
    NULL = -1,
    OK = 200,
    NOT_MODIFIED = 304,  
    FORBIDDEN = 403, 
    NOT_FOUND = 404,    
}


## ValueType 的显示名（索引与下面的枚举一一对应）。
## 被谁用：日志/UI 展示（如 Attributes 里的调试打印）。
static var StrValueType = ["BASE", "CUR", "MIN", "FINAL", "MULTIPLIER"]
## 属性值域：基准/当前/下限/最终/倍率。
## 被谁用：Attributes 的读写与结算、BuffPreset.value_type、InteractionBase.impact。
enum ValueType {
    BASE,
    CUR,
    MIN,
    FINAL,
    MULTIPLIER
}

## buff 的修正方式。被谁用：BuffPreset.method（apply 里 match）。
enum ModificationMethod {
    ADD,
    SUBTRACT,
    MULTIPLY,
    DIVIDE,
    SET
}
## ModificationMethod 的显示符号（索引与上面一一对应，同 StrValueType）。
## 被谁用：UI 展示（属性一览里 buff 的"怎么改"，如 `+10`、`=Health 的当前值`）。
static var StrModificationMethod = ["+", "-", "×", "÷", "="]

## 按键/指针状态名（**也是 UI 与快捷指令里的事件名**）。
## 被谁用：Archetype_System 的 statuses.keys、SystemShortcut 的 PointerDetect.key、UIBase 的事件匹配。
enum KeyStatus{
    HOLD,
    PRESS,
    RELEASE,
    POINTER_MOVE, # 指针移动：不绑键位。**不经状态层**——由 PointerDetect._process 直接派发（位移不为 0 时）
    POINTER_ENTER, # hover 进入：不绑键位，同上（由 PointerDetect._process 直接派发）
    POINTER_EXIT, # hover 离开：不绑键位，同上（由 PointerDetect._process 直接派发）
    # 注意：这三个指针值即使暂时没有使用者也别删——删中间值会让已存盘 json 里的枚举整数串位（见 SysCfg.RESET）。
}

## UI 的开启位置策略（由被开启 UI 自己的 config["open_at"] 声明，见 UIInteract_OpenClose.open/_place）。
## 开独立 UI 与开菜单/提示是一回事：读配置 → 建 UI → 挂到锚点/宿主或 UI 根；差的只是摆在哪。
## 注意 open 的 anchor 参数不只用在这里：它同时是**挂载点**（决定挂在谁下面），见该函数的说明。

# ---- 摆位的**候选顺序**（"开在哪"的次序，见 UIInteract_OpenClose._place / _ordered）----
# 角名**一律英文**（与下面 OpenAt 里的叫法一致，也用不着额外翻译）：
#   `top_right` / `top_left` / `bottom_right` / `bottom_left`
# 意思就是**"把浮窗摆在参照物的哪一角"**。开出来时按这个次序挑"**第一个能完整落在屏幕里**"的位置；
# 全被屏幕挡掉就挑"露出来最多"的那个。
# 两种参照物各一套默认（为什么两套：指针旁优先右下 = 与 Windows 菜单一致；贴锚点优先右上 =
# 子菜单该贴着菜单项的右边往外长）。**想在某个预设上换顺序就写 config["open_order"]**（一串角名，
# 可以只写前几个，如 `["top_left"]`）；**想按"离指针最近"排有两种写法**：
#   · `open_at = OpenAt.ANCHOR_NEAREST`（== 贴锚点 + 挑最近角，悬停说明浮窗用这条；推荐）；
#   · 或在别的策略上再补一条 `config["nearest"] = true`（如"指针旁也挑最近角"）。
# 两种都是"离指针最近优先"，角名顺序只当平手时用。
const OPEN_ORDER_POINTER := ["bottom_right", "bottom_left", "top_right", "top_left"]
const OPEN_ORDER_ANCHOR := ["top_right", "top_left", "bottom_right", "bottom_left"]
enum OpenAt {
    POINTER,          # 开在**指针附近**（右键菜单 / 悬停提示浮窗）：优先"指针右下"，那里放不下会自动
                      # 翻到左下 / 右上 / 左上（见 UIInteract_OpenClose._fit_pos —— 所有策略都带避让）
    ANCHOR_TOP_RIGHT, # 开在"锚点 UI"的右上角顶点（多级菜单：锚点 = 触发它的那个菜单项）；
                      # 右侧放不下会自动翻到锚点左边、下面放不下翻到上面（同一处避让）
    CONFIG,           # 摆回配置里声明的 position（独立面板；被拖动过就回到初值）——不写 open_at 时的默认
    ANCHOR_TOP_RIGHT_IN, # 开在"锚点 UI"**内部**的右上角（按自己的宽度内缩；如给面板加的 "X" 关闭按钮）
    ANCHOR_BOTTOM_RIGHT_IN, # 开在"锚点 UI"**内部**的右下角（如缩放手柄）
    CENTER,           # 开在**屏幕正中**（按屏幕尺寸与自己的尺寸算，"占屏幕一块"的那种窗口用它）
    ANCHOR_RIGHT_OUT, # 外置按钮列：整列贴在"锚点 UI"**右侧外面**——列左沿 = 宿主右边缘、列上沿 = 宿主上边缘，
                      # 往下一个个排（关闭 / 等比缩放 / 改尺寸）。宿主是谁由锚点（或 host）决定，见 UI_Panel._corner_box。
    ANCHOR_NEAREST,   # **贴锚点，挑离指针最近的那个角**（候选还是"锚点顶点周围的四角"，只是改成按
                      # "离指针最近"排 ⇒ 指针在哪边就往哪边冒；**悬停说明浮窗（Tip）用的就是它**）。
                      # 与"`ANCHOR_TOP_RIGHT` + `nearest: true`"是同一件事，只是收进一个 open_at 值里：
                      # 一个"开在哪"的策略只写一处，不必再配一条布尔键（见 UIPreset_Basic.tip_cfg）。
                      # 为什么不直接跟着指针开（`POINTER`）：指针一落进浮窗，事件从浮窗冒泡回锚点、
                      # `meta_hover` 变 null ⇒ 会被当成"离开链接"当场收掉（详见 UIInteract_Meta 文件头）。
    # 注意：新值一律追加在末尾——已存盘的 json 里记的是枚举整数（见 SysCfg.RESET），插在中间会让旧值串位。
}

## LayerType 的显示名（索引与下面的枚举一一对应，COUNT 不参与）。
## 被谁用：MapSys.map_id_to_name（调试名）。
static var StrLayerType = [
    "Middle_P3D", 
    "Middle",
    "Plant",
    "Furniture",
    ]
## 地图逻辑层类型；COUNT 是长度哨兵（不要当层用）。
## 被谁用：TileSetPreset 的 layer、MapLayer 的子层划分、layer_can_match/layer_incompatible。
enum LayerType{
    MIDDLE_P3D,
    MIDDLE,
    PLANT,
    FURNITURE,
    COUNT # 最后一个的序号刚好为长度
}
## "能同时存在"的层组合（中间层放下去时，允许同格还有哪些层的东西）。
## 被谁用：放置判定时参考（当前主要在 MapLayer/TileSetPreset 的层查询里用到）。
static var layer_can_match: Dictionary[LayerType, Array] = {
    LayerType.MIDDLE: [LayerType.MIDDLE, LayerType.PLANT, LayerType.FURNITURE],
    # LayerType.PLANT: [LayerType.MIDDLE, LayerType.PLANT], # 测试用

}
## "不兼容（会占位）"的层组合：某层放东西时，这几个层上有东西就算没空间。
## 被谁用：MapPlaceRulePreset.check_can_place（放置前的空间检查）。
static var layer_incompatible: Dictionary[LayerType, Array] = {
    LayerType.MIDDLE: [LayerType.MIDDLE, LayerType.PLANT, LayerType.FURNITURE],
    LayerType.PLANT: [LayerType.MIDDLE, LayerType.PLANT],
    LayerType.FURNITURE: [LayerType.MIDDLE, LayerType.FURNITURE],

}
