class_name SystemShortcuts
extends BaseClass
## 每个角色的系统快捷集合。
## 被谁用：Character.shortcuts（角色装配时建）；UI 开菜单、按键触发指令等都挂在这里。

## 所属角色。被谁用：add/remove（传给预设去 listen/unlisten）。
var me: Character
## 已装快捷：预设名 -> 预设。被谁用：check_exist、remove。
var shortcuts: Dictionary[String, SystemShortcutPreset] = {}

## 装配：记下所属角色并装入原型声明的快捷。
## 被谁用：Character._init_from_archetype。
func _init(me: Character, shortcuts_name: Array[String]) -> void:
    self.me = me
    add_shortcuts(shortcuts_name)

## 批量加。被谁用：_init、运行时批量加。
func add_shortcuts(shortcuts_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in shortcuts_name:
        codes.append(add_shortcut(name))
    return codes

## 加一个快捷：登记 → 让预设开始监听依赖状态 → 广播。重复加返回 NOT_MODIFIED。
## 被谁用：add_shortcuts、指令。
func add_shortcut(shortcut_name: String) -> Enums.Code:
    if shortcut_name in shortcuts:
        return Enums.Code.NOT_MODIFIED
    var shortcut: SystemShortcutPreset = SystemShortcutPreset.get_(shortcut_name)
    shortcuts[shortcut_name] = shortcut
    shortcut.listen(me)
    Msg.send_shortcut_add(me, shortcut_name)
    return Enums.Code.OK

## 批量移除。被谁用：运行时批量移除。
func remove_shortcuts(shortcuts_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in shortcuts_name:
        codes.append(remove_shortcut(name))
    return codes

## 移除一个快捷：退订监听 → 从字典删 → 广播。
## 被谁用：remove_shortcuts、指令。
func remove_shortcut(shortcut_name: String) -> Enums.Code:
    if not shortcut_name in shortcuts:
        return Enums.Code.NOT_MODIFIED
    shortcuts[shortcut_name].unlisten(me)
    shortcuts.erase(shortcut_name)
    Msg.send_shortcut_remove(me, shortcut_name)
    return Enums.Code.OK

## 有没有装某个快捷。被谁用：条件判定/指令。
func check_exist(shortcut_name: String) -> bool:
    return shortcuts.has(shortcut_name)
