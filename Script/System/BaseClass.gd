class_name BaseClass
extends RefCounted
## 指令化函数基类（设计见 Script/设计文档.md 与下方注释）：
## 项目里所有"能被指令系统调用"的类都继承它（Sys / 各 System / UI 元素 / 预设 等），
## 于是继承者带一个实例 ID，指令串里可以用 @ID 指到具体实例。

## 实例 ID（等于引擎的 instance id）。
## 被谁用：UIBase._resolve_cmd（把 self/self.parent 换成 @ID）、指令系统按 @ID 取回实例。
var ID: int = get_instance_id()

""" ---------- 指令化函数基类 ---------- """
# 有类MapSys，继承于BaseClass
# MapSys有静态方法place，参数如下：
    # static func place(layer_id: int, x: int, y: int,
        # source_name: String = "", tile_name: String = "", variant: int = -1,
        # force_space: bool = false, force_compatible: bool = false) -> void:
# 常规使用方式如下：
    # MapSys.place(0, 15, -14, "门", "1")
# 指令使用方式如下：
# 第一种：按位置传参（参数在括号里，逗号分隔）
# Msg.send_cmd("MapSys.place(0, 5, -10, \"门\", 2, -1, true)")
# 第二种：给参数名传参（名字=值），可以**跳过**中间那些带默认值的参数，例如下面跳过了 variant
# Msg.send_cmd("MapSys.place(layer_id=0, x=10, y=-10, source_name=\"门\", tile_name=2, force_space=true)")
