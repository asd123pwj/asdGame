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

enum LayerType{
    MIDDLE_P3D,
    MIDDLE,
    COUNT # 最后一个的序号刚好为长度
}