class_name Character
extends BaseClass
## 角色：一个实体的全部逻辑部件（属性/状态/交互/技能/碰撞/背包/快捷）+ 可选的身体节点。
## 各部件在 _init_from_archetype 里按 Archetype（原型/种族）配置成套装配，之后互不关心（见 Script/Character/Character.md）。
## 被谁用：CharSys.spawn / create_char（唯一构造入口）；各处用 `Character.get_(注册名)` 取（`Char/人类`）。

## 显示名（不填则用原型名）。被谁用：日志、UI、指令里按名找角色。
var name: String
""" ----- Logic ----- """
## 属性（含 buff 加成与上下限计算）。被谁用：状态/交互/技能、指令里的表达式。
var attrs: Attributes
## 状态集合（每个 StatusPreset 的监听+满足判定）。被谁用：交互/技能/快捷的依赖状态、Statuses.check_satisfied。
var statuses: Statuses
# var behaviors: Behaviors
## 交互集合（属性/背包类操作，如攻击/治疗/吃）。被谁用：InteractionPreset.listen 的触发、指令。
var interactions: Interactions
## 技能集合（逐帧行为，如行走/重力/跳跃）。被谁用：physics_process 里的队列执行。
var skills: Skills
## 碰撞区集合（Area2D 探测，进出关系触发状态）。被谁用：状态的 Detect=>Touch 类判定。
var collisions: Collisions
## 背包集合（按"类型名"存放，如 Backpack/DeadDrop）。被谁用：交互（吃/掉落/搜寻）、指令。
var inventories: Inventories
## 系统快捷集合（依赖状态满足即执行指令串）。被谁用：UI 开菜单、按键绑指令等。
var shortcuts: SystemShortcuts
""" ----- Actor ----- """
## 物理身体（CharacterBody2D，含精灵与碰撞形状）。**延后生成**：直到 ensure_body() 才建。
## 被谁用：技能移动、碰撞区挂载、指针命中角色（PointerDetect._char_at）。
var body: CharacterBody2D = null
## 原型（种族）名。被谁用：取 Archetype 配置、调试展示。
var archetype_type: String = ""
## 独特身份名（如 "player"/"敌人"）：非空就会登记到 CharSys.identities，
## 状态名可以写成 "状态名@identity" 定向到这个角色。被谁用：Msg._resolve_target、状态定向。 
var identity: String = ""
## body 是否已尝试生成过（避免重复尝试；原型没配 bodies 时也算"试过"）。
var _body_created: bool = false

## 角色的注册名前缀：**`Char/原型类型`**（和 UI 的 `UI/` 一个规矩，见 RegSys）。
## 于是"这是角色还是 UI 还是地图"从名字上一眼分得清，子部件照旧 `父名/子名`。
const CHAR_ROOT: String = "Char/"

## 全部角色：**注册名 -> 实例**（`Char/人类`）。
## 被谁用：CharSys._physics_process（逐帧驱动）、Character.get_、PointerDetect._char_at。
static var _we: Dictionary[String, Character] = {}


## 构造：**按原型装配**，顺便给自己登记一个名字（`Char/原型类型`）；`identity` 非空则登记成"身份"。
## 被谁用：CharSys.create_char（唯一入口，不要在别处直接 new）。
## 名字怎么来：`Char/` + 原型类型（"人类" ⇒ `Char/人类`）；**同原型的第 2、3 个自动让路加后缀**
## （`Char/人类_2`，见 RegSys.register 的 dedup）——注册名全项目唯一，不让路的话第二个会顶掉第一个的名字，
## 而 `_we` 是按注册名索引的（被顶掉的那个就再也驱动不到、也取不到了）。
## **名字与身份是两回事**（别混）：名字是"这一个实例叫什么"（跟它一辈子、唯一）；
## 身份是"现在由谁来演这个位子"（`CharSys.identities`，同一个身份换个时候可以指向别的角色——
## 重生/换身就是改绑身份）。所以状态名可以写 `"状态名@身份"` 定向过去，而指令里按**名字**指到具体实例。
func _init(archetype_type: String, identity: String = "") -> void:
    self.name = archetype_type
    # 登记并**接住真正用上的那个名字**（去重也在注册系统里，一次调用就够）
    var reg_name: String = RegSys.register(self, CHAR_ROOT + archetype_type, true)
    _we[reg_name] = self
    self.identity = identity
    if identity != "":
        CharSys.bind_identity(identity, self)
    _init_from_archetype(archetype_type)
    init_done()


## 按**注册名**取角色（`Char/人类`；没有返回 null）。
## 被谁用：指令里的 `@Char/人类`、需要按名字反查的地方。
static func get_(reg_name: String) -> Character:
    return _we.get(reg_name, null)

## 物理帧：交给技能系统（技能队列 + move_and_slide）。
## 被谁用：CharSys._physics_process。
func physics_process(delta: float) -> void:
    skills.physics_process(delta)

## 按原型里的各字段名，成套 new 出各部件（部件内部会自己去读同名预设）。
## 被谁用：_init。
func _init_from_archetype(archetype_type: String) -> void:
    self.archetype_type = archetype_type
    var archetype: Archetype = Archetype.get_(archetype_type)
    attrs = Attributes.new(self, archetype.buffs)
    statuses = Statuses.new(self, archetype.statuses)
    # behaviors = Behaviors.new(self, archetype.behaviors)
    interactions = Interactions.new(self, archetype.interactions)
    skills = Skills.new(self, archetype.skills)
    collisions = Collisions.new(self, archetype.collisions)
    inventories = Inventories.new(self, archetype.inventories)
    shortcuts = SystemShortcuts.new(self, archetype.shortcuts)

## 部件装完后的收尾：让状态做"首次判定"（状态可能在装配前就已满足）。
## 被谁用：_init。
func init_done() -> void:
    statuses.char_init_done()

## body 延后生成：首次需要时创建；archetype 未配 bodies 则留空返回 null
## 被谁用：CharSys.spawn、需要身体时（碰撞/技能）。
func ensure_body() -> CharacterBody2D:
    if _body_created:
        return body
    _body_created = true
    var bodies: Array[String] = Archetype.get_(archetype_type).bodies
    if bodies.is_empty():
        return null
    var body_name: String = bodies[0]
    body = BodyPreset.get_(body_name).create()
    body.set_meta("character", self)
    if body_name == "Human":
        body.position = Vector2(64, 128)
    else:
        body.position = Vector2(640, 128)
    @warning_ignore("unsafe_method_access")
    collisions.attach_collisions()
    return body
