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

static var StrLayerType = ["Back_P3D", "Back", "Middle_P3D", "Middle", "Front_P3D", "Front"]
enum LayerType{
    BACK_P3D,
    BACK,
    MIDDLE_P3D,
    MIDDLE,
    FRONT_P3D,
    FRONT,
    COUNT # 最后一个的序号刚好为长度
}