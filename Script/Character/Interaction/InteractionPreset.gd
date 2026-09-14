class_name InteractionPreset
extends PresetRegister
## 交互预设：依赖某状态满足 → 执行一次具体的"交互实现"（属性/背包类操作）。
## 触发时会把"最近一次依赖状态消息里的 target"交给实现类，所以交互能知道对象是谁。
## 被谁用：Interactions.add_interaction（装到角色身上）、Archetype 的 interactions 字段。

## 预设名（唯一）。被谁用：Interactions 的字典键、消息与指令。
var name: String
## 实现类名（InteractionBase 子类，如 "Interaction_Attack"）。被谁用：_get_interaction_by_name。
var interaction_name: String
## 依赖的状态名（支持 "状态名@identity" 定向）。被谁用：listen。
var dependence_status: String
## 传给实现类的参数。被谁用：_get_interaction_by_name（构造时传入）。
var config
## 实现类实例（**每个预设一个**，构造时就拿到 config）。被谁用：listen。
var interaction 

## 全部预设：名 -> 实例。被谁用：InteractionPreset.get_。
static var _we: Dictionary[String, InteractionPreset] = {}
# {Char: {msg_ID: func}}
## 每个角色各自登记的触发函数（用于 unlisten）。被谁用：listen/unlisten。
var _trigger_funcs: Dictionary[Character, Dictionary] = {}

## 注册一条交互预设，并按类名实例化实现类（把 config 直接交给它）。
## 被谁用：PresetRegister 的注册流程、Archetype 内联配置。
func _init(name: String, interaction_name: String, dependence_status: String, config = null) -> void:
    _we[name] = self
    self.name = name
    self.interaction_name = interaction_name
    self.dependence_status = dependence_status
    self.config = config
    _get_interaction_by_name()

## 按类名从全局类表取实现类并 new（取不到报错）。
## 被谁用：_init。
func _get_interaction_by_name() -> void:
    for cls in ProjectSettings.get_global_class_list():
        if cls["class"] == interaction_name:
            @warning_ignore("unsafe_method_access")
            # 我突然发现我这里用的是new，那意味着每个name都有各自的interaction，所以不如直接传配置进去初始化，省得在listen里传
            interaction = load(cls["path"]).new(name, config)
            return
    push_error("找不到类: ", interaction_name)
    interaction = null

## 按名取预设。被谁用：Interactions.add_interaction。
static func get_(name: String) -> InteractionPreset:
    return _we[name]

## 给某角色登记触发：监听"依赖状态满足"（listen_status_satisfied）→ 取该状态最近一条消息里的 target → 执行交互。
## 被谁用：Interactions.add_interaction。
func listen(char_: Character) -> void:
    _trigger_funcs[char_] = {}
    var trigger_func = func (_msg) -> void:
        # 之前想着以_msg作为target，结果发现status监听不到target，_msg不可能是target
        # 所以改为了去读取target，
        # var target = Msg.get_status_detected(char_, dependence_status)
        # 我比天才更天才，谁说status不能监听target了
        var target = char_.statuses.get_latest_message(dependence_status)
        @warning_ignore("unsafe_method_access")
        interaction.interact(char_, target)
        Msg.send_interaction_act(char_, name)
    var msg_ID = Msg.listen_status_satisfied(char_, dependence_status, trigger_func)
    _trigger_funcs[char_][msg_ID] = trigger_func

## 退订该角色的全部触发函数。被谁用：Interactions.remove_interaction。
func unlisten(char_: Character) -> void:
    for msg_ID in _trigger_funcs[char_].keys():
        MsgBus.unlisten(msg_ID, _trigger_funcs[char_][msg_ID])
    _trigger_funcs.erase(char_)
