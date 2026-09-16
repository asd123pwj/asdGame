class_name BaseClass
extends RefCounted
## 指令化函数基类（设计见 Script/设计文档.md 与下方注释）：
## 项目里所有"能被指令系统调用"的类都继承它（Sys / 各 System / UI 元素 / 预设 等），
## 于是继承者带一个实例 ID，指令串里可以用 $@ID 指到具体实例。

## 实例 ID（等于引擎的 instance id）。
## 被谁用：UIBase._resolve_cmd（把 $self/$parent 换成 $@ID）、指令系统按 $@ID 取回实例。
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
# 第一种：固定位置传参，无需指定参数名
# Msg.send_cmd("MapSys.place 0 5 -10 门 2 -1 true")
# 第二种，使用指定参数名传参，无需指定位置，可跳过含默认参数的参数，例如下面跳过了variant
# Msg.send_cmd("MapSys.place --layer_id 0 --x 10 --y -10 --source_name 门 --tile_name 2 --force_space")
