class_name Enums


enum Code {
    NULL = -1,
    OK = 200,
    NOT_MODIFIED = 304,  
    FORBIDDEN = 403, 
    NOT_FOUND = 404,    
}


static var StrValueType = ["BASE", "CUR", "MIN", "FINAL", "MULTIPLIER"]
enum ValueType {
    BASE,
    CUR,
    MIN,
    FINAL,
    MULTIPLIER
}

enum ModificationMethod {
    ADD,
    SUBTRACT,
    MULTIPLY,
    DIVIDE,
    SET
}

enum KeyStatus{
    HOLD,
    PRESS,
    RELEASE,
    POINTER_MOVE, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
    POINTER_ENTER, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
    POINTER_EXIT, # 不支持键位绑定，键值统一用 MOUSE_BUTTON_NONE 占位（任意占位均可，项目内保持一致）
}

static var StrLayerType = [
    "Middle_P3D", 
    "Middle",
    "Plant",
    "Furniture",
    ]
enum LayerType{
    MIDDLE_P3D,
    MIDDLE,
    PLANT,
    FURNITURE,
    COUNT # 最后一个的序号刚好为长度
}
static var layer_can_match: Dictionary[LayerType, Array] = {
    LayerType.MIDDLE: [LayerType.MIDDLE, LayerType.PLANT, LayerType.FURNITURE],
    # LayerType.PLANT: [LayerType.MIDDLE, LayerType.PLANT], # 测试用

}
static var layer_incompatible: Dictionary[LayerType, Array] = {
    LayerType.MIDDLE: [LayerType.MIDDLE, LayerType.PLANT, LayerType.FURNITURE],
    LayerType.PLANT: [LayerType.MIDDLE, LayerType.PLANT],
    LayerType.FURNITURE: [LayerType.MIDDLE, LayerType.FURNITURE],

}