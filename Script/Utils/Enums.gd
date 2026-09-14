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

## 按键/指针状态名（**也是 UI 与快捷指令里的事件名**）。
## 被谁用：Archetype_System 的 statuses.keys、SystemShortcut 的 PointerDetect.key、UIBase 的事件匹配。
enum KeyStatus{
    HOLD,
    PRESS,
    RELEASE,
    POINTER_MOVE, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
    POINTER_ENTER, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
    POINTER_EXIT, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
}

## UI 的开启位置策略（由被开启 UI 自己的 config["open_at"] 声明，见 UiSys.open_ui/_place）。
## 开独立 UI 与开菜单/提示是一回事：读配置 → 建 UI → 挂到锚点/宿主或 UI 根；差的只是摆在哪。
## 注意 open_ui 的 anchor 参数不只用在这里：它同时是**挂载点**（决定挂在谁下面），见 UiSys 文件头。
enum OpenAt {
    POINTER,          # 开在指针处（右键菜单）
    ANCHOR_TOP_RIGHT, # 开在"锚点 UI"的右上角顶点（多级菜单：锚点 = 触发它的那个菜单项）
    CONFIG,           # 摆回配置里声明的 position（独立面板；被拖动过就回到初值）——不写 open_at 时的默认
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
