# UI 系统设计文档

> 本文档是 UI 系统的**权威设计参考**。所有后续代码修改、需求变更，都应同步更新本文件，避免反复口头沟通。

## 1. 目标

- 用 **ConfigBase.values**（继承现有配置体系）描述 UI，使玩家可通过修改生成的配置 json 获得最大自定义权限。
- UI 描述用 **JSON/Dictionary 自描述结构**，让 AI（LLM）与人类都易于理解。
- UI 从**游戏运行数据**取值（角色血量等），复用现有「指令系统」（静态/实例取值、消息总线）。

## 2. 目录与命名约定

```
Script/UI/
├─ UI设计.md            # 本文档
├─ UIBase.gd            # 自定义 UI 元素构造器基类（extends BaseClass/ConfigBase 体系）
├─ UiBuilder.gd         # 把 values 里的 UI 描述 Dictionary -> Godot Control 树
├─ UiSystem.gd          # 根节点管理、加载配置、挂到主场景 CanvasLayer、绑定刷新
└─ UI/                 # 自定义元素放置目录（元素类）
   └─ UI_HPBar.gd      # 示例自定义元素（class_name UI_HPBar）
```

命名约定：
- 自定义元素类 `class_name UI_HPBar`，type 名 = 去掉 `UI_` 前缀 → `HPBar`。
- 元素类统一放 `Script/UI/UI/` 下。
- UI 配置类：`class_name UIPreset_XXX extends ConfigBase`（`values` 数组里列多个 UI 描述），放置于 `Config/UI/`。

## 3. UI 描述 = values 里一个 Dictionary

一个 UI 的完整描述是一个自描述 Dictionary。UI 配置类只承载 `values: Array[Dictionary]`，结构全在 Dictionary 内部表达。

```jsonc
// Config/UI/UIPreset_XXX.gd 的 values 其中一项
{
  "name": "PlayerHUD",          // UI 唯一标识名
  "style": { ... },             // 本 UI 的显示属性（见 §4）
  "root": { ... }               // 根元素描述（一棵元素树），见 §5
}
```

## 4. 显示属性与默认值模型（style）

UI 整体与每个元素都要能指定显示属性：位置、大小、字体、字体大小、颜色、背景、透明度、边距等（见下表）。

**取值规则（从里到外逐级回退）：**
1. 元素自身 `style` 里显式指定的值
2. 父元素的 `style`
3. UI 根级 `style`
4. **全局默认值**（系统级默认：字体、字体大小等，集中一处定义）
5. 若从未被任何层级/修改覆盖 → 用默认；被改过 → 用改过的值（见 §7 覆盖来源）

```jsonc
"style": {
  "position": [0, 0],      // 位置
  "size": [200, 40],       // 尺寸
  "font": "默认字体",        // 字体名
  "font_size": 16,         // 字号
  "color": "#FFFFFF",      // 文字颜色
  "bg": "#000000AA",       // 背景色
  "margin": [0,0,0,0],     // 外边距
  "padding": [0,0,0,0],    // 内边距
  "anchor": [0,0,1,0]      // 锚点（相对父）
}
```

属性类型与 ConfigBase 的 `_assign_property` 兼容（Vector 用数组、Color 用十六进制串）。

### 全局默认值来源
字体、字号等"绝大多数元素一致"的属性收敛到一处**全局默认 style**，避免每个 UI 重复写。个体默认（如位置、背景）在对应 UI/元素 style 里写；未写则回退到全局默认。

## 5. 元素树（root / children / 引用）

一个元素描述 Dictionary：

```jsonc
{
  "type": "VBox",            // 原生 type 或自定义 type（见 §6）
  "name": "leftPanel",       // 节点名（供查找/绑定）
  "style": { ... },          // 本元素显示属性（可选）
  "text": "HP {hp}",         // 文本（Label/Button 等原生属性）
  "cmd": "BagSys.open 0",    // 点击要发的命令（可选）
  "bind": "hp",              // 数据绑定名（可选，见 §8）
  "track": "$@12345",        // 本元素追踪源（可选；不写则继承父/根）
  "children": [ ... ]        // 子元素数组（可选）
}
```

- `children` 递归生成，直到叶子。
- 原生控件额外属性（text/cols 等）直接作为同层键传给对应 Godot 节点。

### 引用其它 UI 作为子 UI
- 元素可用 `"ref": "UI名"` 引用另一个已定义 UI 作为子结构，避免重复写配置。
- 支持嵌套引用（被引用的 UI 也能引用别的 UI）。
- **循环引用检测**：若 A↔B 互相引用（或引用自身），在解析时检测并**报错**，防止死循环。

```jsonc
{ "ref": "HPLabel", "style": { "font_size": 20 } }   // 引用名为 HPLabel 的 UI 作为子元素
```

### UI 继承 UI（extends）
一个 UI 配置可以**继承**另一个 UI 配置（父），用于做"外观变体"——父配置给全所有值，子只写不同的值即可。

- 语义：子 **extends** 父后，先照搬父的整棵定义（style + children）作为基底，子**显式指定的属性/子元素覆盖**父的对应项。
- 覆盖发生在**本层属性**；不增删结构（子若想增删 children 属后续扩展）。
- 典型用法：先写一个**基础按钮/HPBar 配置**（schema 字段都确定、值给全），再写竖版/圆形等**变体配置**，仅覆盖它们与基础不同的值。

```jsonc
// values 里两个 UI 描述
{
  "name": "BtnBase", "type": "Button",
  "style": { "position": [0,0], "size": [120,40], "font_size": 16, "bg": "#666666" }
},
{
  "name": "BtnVertical",
  "extends": "BtnBase",        // 继承 BtnBase 的整棵定义
  "style": { "size": [40,120] }  // 仅覆盖与 BtnBase 不同的值
}
```

UiBuilder 遇到 `extends`：先解析出父 UI 定义 → 深拷贝为基底 → 将子记录的显式字段（style 等）覆盖到基底上 → 得到完整定义后再走正常生成。**循环继承检测**（A extends B 且 B extends A）要报错。

### ref（引用当子节点）与 extends（继承变体）的区别
- `ref`：A 把 B **当子节点**嵌进自己的树（B 是 A 的孩子）。
- `extends`：A 是 B 的**变体/继承体**，先整体取 B 的定义再覆盖差异（B 是 A 的父模板）。两者不要混用。

## 6. type 体系（混合映射）

- **原生 type**：`Label / Button / Panel / VBox / HBox / Grid / Scroll / ProgressBar ...` → UiBuilder 内部映射到 Godot 原生 Control。
- **自定义 type**：`HPBar / Slot / Dialog / ...` → `class_name UI_HPBar extends UIBase` 的元素类。

UiBuilder 解析顺序：
1. 元素含 `ref` → 按引用展开（先解析被引用的 UI）。
2. `type` 在原生表 → new 原生 Control。
3. `type` 是自定义元素 → 找 `UI_` 前缀类，实例化并调用其 `build`。
4. 含 `children` → 逐个递归。

## 7. UIBase 与元素构造器

`UIBase.gd` 是自定义元素构造器的基类，负责把一段元素描述转成 Godot 节点（**元素不是 Control 子类，而是构造器**，`build` 返回节点）。

```gdscript
class_name UIBase
extends BaseClass

# 子类：class_name UI_HPBar extends UIBase
# type 名 = class_name 去掉 "UI_"

# 用描述 + 上下文构造一个 Control 子树并返回
# ctx: 含根追踪源、绑定表、样式解析器、UiSystem 引用等
func build(ctx: Dictionary, desc: Dictionary) -> Control:
    push_error("UIBase.build 需被子类实现")
    return null
```

### 默认 style 继承链的实现
UiBuilder 在递归 children 时，把"当前生效 style（合并了父链）"通过 `ctx.style` 传下去；每个元素的 `style` 合并进它（近的覆盖远的）。最终渲染 Godot Control 时用合并后的 style 设置属性。

## 8. 数据绑定与追踪（tracking）

### 追踪源（track）
- UI 运行时需要一个"从哪个实例取数据"的追踪源，通常是某角色实例 ID。
- 由**实例化时外部传入**（如 `$@玩家ID`），**不写死在配置**里。
- 每个元素若没显式 `track`，则**向上继承**：子元素的追踪源继承父元素，父没有继续往上，直到 UI 根级传入的追踪源。因此树内数据默认都来自根追踪实例。
- 静态取值无需追踪（直接取）。

### 取值表达
复用现有指令系统取值表达式（见 CommandSystem / CommandParser）：
- 静态：`&Test.xxx` / `$Test.xxx`
- 实例（经追踪源相对取或显式 ID）：`$@实例ID.属性`，链式 `.prop[下标]` / 调方法。

### 绑定刷新
元素通过 `bind` 声明绑定的数据，UiSystem 订阅对应消息（角色状态变化等），变化时用当前追踪源重新取值并刷新节点（文本/进度条/图片）。

## 9. UiBuilder 与 UiSystem

- **UiBuilder.build(uiDesc, ctx) -> Control**：把 values 里一个 UI 描述 Dictionary 解析成一棵 Control 树，返回根节点。
- **UiSystem**：持有 UI 根（挂到主场景 CanvasLayer 下），加载某 UI 配置 → build → 挂载；管理追踪源、绑定表、刷新循环、热重载（重载配置 json → 重建）。

## 10. 玩家/开发者编辑能力（后续）

- UI 显示属性可通过一个"编辑 UI"修改（右键菜单 → 编辑）。
- 编辑结果落到配置值：显式覆盖对应属性（走 §4 的覆盖来源），未改的继续回退默认。
- 布局上支持多版本（字体大小、横竖屏等）为后续扩展点，暂不实现。

## 11. 已确认但暂缓

- 横屏/竖屏、字体缩放等多套 UI 版本（字段留扩展，未做）。
- 用"UI 改 UI"的可视化编辑器（右键菜单编辑）。
- 自定义元素体系正式落地（先以 HPBar 验证）。

## 12. 变更日志

- (初始) 确立整体设计：ConfigBase.values 承载 UI 描述、style 默认值回退链、追踪链、嵌套引用防环、type 原生/自定义混合。
- (新增) UI 继承 UI（extends）：子配置先整体照搬父的 style+children，子显式指定才覆盖（本层属性，不增删结构）；用于"基础配置给全值 + 变体只覆盖差异"，如基础按钮 → 竖版/圆形按钮；循环继承需报错。
- (最小原型) 已搭：UIBase.gd(元素构造器基类)、UiBuilder.gd(原生 type+children+style 合并回退)、UI/UI_HPBar.gd(示例自定义元素)、Config/UI/UIPreset_Basic.gd(MiniHUD 示例)、test.gd.ui_test 生成并挂载验证。尚未实现：自定义元素之外更完善的绑定刷新、ref/extends、UiSystem 主管理、多版本。extends/ref 语义已定，实现留待下一阶段。
