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
    DOWN,
    FIRST_DOWN,
    UP,
    FIRST_UP
}

static var StrLayerType = [
    "Middle_P3D", 
    "Middle",
    "Plant"
    ]
enum LayerType{
    MIDDLE_P3D,
    MIDDLE,
    PLANT,
    COUNT # 最后一个的序号刚好为长度
}
static var layer_can_match: Dictionary[LayerType, Array] = {
    LayerType.MIDDLE: [LayerType.MIDDLE, LayerType.PLANT],
    LayerType.PLANT: [LayerType.MIDDLE, LayerType.PLANT],

}