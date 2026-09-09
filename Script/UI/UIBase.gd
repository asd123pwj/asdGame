class_name UIBase
extends BaseClass
## 自定义 UI 元素构造器基类（文档见 Script/UI/UI设计.md §7）。
## 子类命名：class_name UI_HPBar extends UIBase（type 名 = 去掉 "UI_" 前缀 -> "HPBar"）。
## 元素是"构造器"，不是 Control 子类：build() 依据描述 Dictionary 生成一棵 Control 子树并返回。
## 元素类统一放 Script/UI/UI/ 目录。


# 由 UiBuilder 在递归时构建；返回 [ok, node]。node 是新建的 Control 子树。
# _ctx 提供运行时上下文：追踪源、当前生效 style、绑定点、UiSystem 引用等。
# _desc 是这段元素的描述 Dictionary。
func build(_ctx: Dictionary, _desc: Dictionary) -> Array:
	push_error("UIBase.build 需被子类实现: ", get_class())
	return [false, null]
