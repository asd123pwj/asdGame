class_name UIPreset_Test
extends ConfigBase

""" ---------- 测试用 UI（两个）----------
"一个 UI 的信息提交给另一个 UI"的最小例子（按名称绑定，见 Script/UI/Interact/UIInteract_Bind.gd）：

  TestShow   显示文本（整块就是个 UI_Scroll）。它也是"复制名称"的来源：
               右键 TestShow → 复制名称 → 再右键 TestInput → 绑定 ▸ → 回车
  TestInput  输入文本（UI_Panel + UI_Input）：在输入框里打字回车 → 把文本发给 config["bind"] 指的那个 UI。

两个都是**独立 UI**（没有宿主）：
  - 默认开出来：Test.ui_test 里两条 `UIInteract.open --preset_name ...`；
  - J / K 键开关它们：状态层的按键快捷，见 Config/Character/Archetype/Archetype_System.gd。

两个都可以右键（菜单挂在它自己下面）：复制名称 / 绑定 ▸ / 菜单编辑（菜单那套是通用的）。
"""
var values: Array[Array] = [
    # 显示用：整块就是一个滚动文本，收到什么显示什么（提交链就是写它的 config["content"] 再刷新）
    ["TestShow", "UI_Scroll", {
        "position": [380, 30], "size": [260, 140],
        "content": "（还没收到东西）",
        "events": [[QName.mouseRight, "UIInteract.open $self Menu $self --close_on_blur"]],
    }],
    # 输入用：标题 + 输入框 + 一句提示；回车提交 → 发给绑定的那个 UI
    ["TestInput", "UI_Panel", {
        "position": [380, 190], "size": [260, 0],
        "events": [[QName.mouseRight, "UIInteract.open $self Menu $self --close_on_blur"]],
        "children": [
            ["Title", "UI_Label", {"content": "TestInput（打字后回车）"}],
            ["Name", "UI_Input", {
                "size": [240, 0],
                # 输入框自己**没有任何特判**：点它进编辑、回车提交，都是这里配的事件→指令。
                "events": [
                    # 点它进编辑（元素不写死"鼠标左键"：换成别的事件照样能用）
                    [QName.mouseLeft, 'UIInteract.begin_edit $self'],
                    [QName.input_submit,
                        # 提交 = 全是普通命令：送到绑定名指的那个 UI + 清空自己 + 退出编辑 + **改了什么就刷什么**。
                        # 路径**用双引号包住** = 字面字符串（`$` 开头也不会被当成取值式），所以不用手写 `\$`。
                        # **指令串外层用单引号**：里面那对双引号就不用转义成 `\"`（Godot 两种引号都行）。
                        # 顺序别反——编辑中的输入框会跳过刷新（免得把正在打的字冲掉），先刷就把"清空"漏掉了。
                        'Utils.write "$UiSys.get_ui($self.parent.config.bind).config.content" $self.control.text'
                        + '\vUtils.write "$self.config.content"'                        # 不写值 = 清空框
                        + '\vUIInteract.end_edit $self'                                 # 想"提交完继续打字"就不写这条
                        + '\v$UiSys.get_ui($self.parent.config.bind).refresh("content")'   # 只刷改过的那一项
                        + '\v$self.refresh("content")'],                                   # 自己也是只改了 content
                ],
            }],
            ["Tip", "UI_Label", {"content": "未绑定就回车会提示（右键我 → 绑定 ▸）"}],
        ],
    }],
]
