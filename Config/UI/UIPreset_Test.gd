class_name UIPreset_Test
extends ConfigBase

""" ---------- 测试用 UI（两个）----------
"一个 UI 的信息提交给另一个 UI"的最小例子（按名称绑定，见 Script/UI/Interact/UIInteract_Bind.gd）：

  TestShow   显示文本（整块就是个 UI_Scroll）。它也是"复制名称"的来源：
               右键 TestShow → 复制名称 → 再右键 TestInput → 绑定 ▸ → 回车
  TestInput  输入文本（UI_Panel + UI_Input）：在输入框里打字回车 → 把文本发给 config["content_cmd"] 指的路径（如 "@UI/TestShow.config.content"）。

两个都是**独立 UI**（没有宿主）：
  - 默认开出来：Test.ui_test 里两条 `UIInteract.open(preset_name="...")`；
  - J / K 键开关它们：状态层的按键快捷，见 Config/Character/Archetype/Archetype_System.gd。

两个都可以右键（菜单挂在它自己下面）：复制名称 / 绑定 ▸ / 菜单编辑（菜单那套是通用的）。
"""
var values: Array[Array] = [
    # 显示用：整块就是一个滚动文本，收到什么显示什么（提交链就是写它的 config["content"] 再刷新）
    ["TestShow", "UI_Scroll", {
        "position": [380, 30], "size": [260, 140],
        "content": "（还没收到东西）",
        "events": [QName.UI_event_mouseRight_menu],
    }],
    # 输入用：标题 + 输入框 + 一句提示；回车提交 → 发给绑定的那个 UI
    ["TestInput", "UI_Panel", {
        # 提交后写到哪儿：**一条路径**（不再有"先记名字、再按名字查"那层转手）。
        # 想发给别的 UI 就改这儿（或右键目标 → 菜单编辑 ▸ → 复制名称 → 填成一整条路径）。
        "content_cmd": "@UI/TestShow.config.content",   # 提交后写到哪儿：就一条路径（标准项，见 UIBase.refresh / UI_Editor）
        "position": [380, 190], "size": [260, 0],
        "events": [QName.UI_event_mouseRight_menu],
        "children": [
            ["Title", "UI_Label", {"content": "TestInput（打字后回车）"}],
            ["Name", "UI_Input", {
                "size": [240, 0],
                # 输入框自己**没有任何特判**：点它进编辑、回车提交，都是这里配的事件→指令。
                "events": [
                    # 点它进编辑（元素不写死"鼠标左键"：换成别的事件照样能用）
                    QName.UI_event_mouseLeft_edit,
                    [QName.input_submit,
                        # 提交 = 全是普通命令：送到绑定名指的那个 UI + 清空自己 + 退出编辑 + **改了什么就刷什么**。
                        # 路径写成**带引号的字符串**：引号里的内容不再被当成取值式，路径原样传给函数。
                        # **指令串外层用单引号**：里面那对双引号就不用转义成 `\"`（Godot 两种引号都行）。
                        # 顺序别反——编辑中的输入框会跳过刷新（免得把正在打的字冲掉），先刷就把"清空"漏掉了。
                        'Utils.write(@host.config.content_cmd, @self.control.text)'
                        + '\vUtils.write("@self.config.content")'                        # 不写值 = 清空框
                        + '\vUIInteract.end_edit(@self)'
                        + '\vUISys.refresh_all()'                                 # 想"提交完继续打字"就不写这条
                        + '\v@self.refresh("content")'],                                   # 自己也是只改了 content
                ],
            }],
            ["Tip", "UI_Label", {"content": "未绑定就回车会提示（右键我 → 绑定 ▸）"}],
        ],
    }],
]
