class_name BaseClass
extends RefCounted
## 指令化函数基类（设计见 Script/设计文档.md 与下方注释）：
## 项目里所有"能被指令系统调用"的类都继承它（Sys / 各 System / UI 元素 / 预设 等）。
##
## **这里没有 ID 了**：以前每个继承者带一个实例 ID，指令串里用 `@ID` 指到具体实例；现在**寻址一律用注册名**
## （`@UI/MiniHUD/Menu`、`@Char/人类`，见 RegSys）——ID 每次运行都变、写进配置就废，人对不上。
## 需要"指到某个实例"的类自己登记名字（UI 走 UISys 登记整棵树，角色走 Character._init）。

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
