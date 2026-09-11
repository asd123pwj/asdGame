class_name SystemShortcuts
extends BaseClass
## 每个角色的系统快捷集合。


var me: Character
var shortcuts: Dictionary[String, SystemShortcutPreset] = {}

func _init(me: Character, shortcuts_name: Array[String]) -> void:
    self.me = me
    add_shortcuts(shortcuts_name)

func add_shortcuts(shortcuts_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in shortcuts_name:
        codes.append(add_shortcut(name))
    return codes

func add_shortcut(shortcut_name: String) -> Enums.Code:
    if shortcut_name in shortcuts:
        return Enums.Code.NOT_MODIFIED
    var shortcut: SystemShortcutPreset = SystemShortcutPreset.get_(shortcut_name)
    shortcuts[shortcut_name] = shortcut
    shortcut.listen(me)
    Msg.send_shortcut_add(me, shortcut_name)
    return Enums.Code.OK

func remove_shortcuts(shortcuts_name: Array[String]) -> Array[Enums.Code]:
    var codes: Array[Enums.Code] = []
    for name in shortcuts_name:
        codes.append(remove_shortcut(name))
    return codes

func remove_shortcut(shortcut_name: String) -> Enums.Code:
    if not shortcut_name in shortcuts:
        return Enums.Code.NOT_MODIFIED
    shortcuts[shortcut_name].unlisten(me)
    shortcuts.erase(shortcut_name)
    Msg.send_shortcut_remove(me, shortcut_name)
    return Enums.Code.OK

func check_exist(shortcut_name: String) -> bool:
    return shortcuts.has(shortcut_name)
