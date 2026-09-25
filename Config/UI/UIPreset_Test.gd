class_name UIPreset_Test
extends ConfigBase

""" ---------- 测试用 UI ----------
"一个 UI 的信息提交给另一个 UI"的最小例子（按名称绑定，见 Script/UI/Interact/UIInteract_Bind.gd）：

  TestShow   显示文本（整块就是"一块会滚的文本"：UI_Panel + 正文子元素）。它也是"复制名称"的来源：
               右键 TestShow → 复制名称 → 再右键 TestInput → 绑定 ▸ → 回车
  TestInput  输入文本（UI_Panel + UI_Input）：在输入框里打字回车 → 把文本发给 config["content_cmd"] 指的路径（如 "@UI/TestShow.config.content"）。

两个都是**独立 UI**（没有宿主）：
  - 默认开出来：Test.ui_test 里两条 `UIInteract.open(preset_name="...")`；
  - J / K 键开关它们：状态层的按键快捷，见 Config/Character/Archetype/Archetype_System.gd。

两个都可以右键（菜单挂在它自己下面）：复制名称 / 绑定 ▸ / 菜单编辑（菜单那套是通用的）。

  MatrixTest  矩阵网格：版式写在面板 config 的 `matrix` 里——同一个编号出现几格 = 那个元素
              跨几格 / 跨几行；想进网格的子元素写一个 `grid: 编号`，面板负责按矩阵把它们的
              position/size 算好（几何函数 `UI_Panel.grid_rect`）——**拖"改尺寸"手柄，
              格子按比例跟着缩放**。跨格 / 跨行天然支持，不用容器、不用嵌套。

  BagTest     等大网格（背包那种）：每个格子一样大（面板 config 的 `cell` = [宽, 高]），
              **列数随内容区宽度变**——拖宽一点，东西就往上走一行；多出来不够一格的空位
              **摊进间距**（撑到能多塞一列就换行）；排不下时面板出滚动条（见 UI_Panel._layout_uniform）。
"""
## 矩阵网格的演示格子：一个带底图的标签，`grid` 序号对应矩阵里的编号
## （面板会按矩阵把它的 position/size 算好；拖"改尺寸"手柄时跟着缩放）。
static func _gcell(id: int, text_: String) -> Array:
    return [str(id), "UI_Label", {
        "grid": id,
        "content": "%d：%s" % [id, text_],
        "background": UIPreset_Keyboard.KEY_BG, "background_slice": UIPreset_Keyboard.KEY_BG_SLICE,
        "font_color": UIPreset_Keyboard.FONT_COLOR,
    }]


## 等大网格的演示格子（背包那种）：n 个一样大的格子，内容 = 序号。
## **顺序就是 children 的顺序**（等大网格按声明顺序铺，不看 `grid`）。
static func _bag_cells(n: int) -> Array:
    var out: Array = []
    for i in n:
        out.append(["Cell%d" % i, "UI_Panel", {
            "margin": 0,
            "background": UIPreset_Keyboard.KEY_BG, "background_slice": UIPreset_Keyboard.KEY_BG_SLICE,
            "children": [["Text", "UI_Label", {
                "content": str(i + 1), "font_color": UIPreset_Keyboard.FONT_COLOR,
            }]],
        }])
    return out


var values: Array[Array] = [
    # 显示用：一块"会滚的文本"（面板 + 正文子元素，见 UIPreset_Basic.text_item），收到什么显示什么
    # 提交链写的是**外壳**的 config["content"]，之后刷整棵（正文是子元素）——TestInput 的 content_cmd 指着它
    ["TestShow", "UI_Panel", {
        "position": [380, 30], "size": [260, 140],
        "events": [QName.UI_event_pointer2_menu],
        "children": [UIPreset_Basic.text_item("（还没收到东西）")],
    }],
    # 拖右下角改尺寸 / 同角多图标自动排位——两件事一起测（实现见 UIInteract_Resize 与 UI_Panel._corner_box）：
    #   · **以面板为准**（`fit_content = false`，尺寸定死）⇒ 拖大拖小时**里面的文字跟着折行**；
    #   · 装不下的内容在**框内滚动**（竖向滚动条自动出，不画到面板外）；
    #   · 关闭 / 等比缩放 / 改尺寸三个手柄由 `Test.ui_test` 开出来（和键盘 UI 同一套写法）；
    #     右上角只有一个图标时不排队，两个手柄同角时**后开的排左边**（先在右 = 等比缩放）。
    ["SizeTest", "UI_Panel", {
        "position": [100, 130],
        "fit_content": false,                     # ← 以面板为准：尺寸由面板说了算，内容跟着折行
        "size": [320, 220],                       # 定死（拖右下角手柄可改，改了会写回这里）
        "margin": 12,                             # 内边距：四边各 12（不写 = 默认 8）
        "events": [QName.UI_event_pointer1_drag], # 按住空白/文字都能拖（子元素没绑的事件会冒泡上来）
        "children": [
            ["Title", "UI_Label", {"content": "右下角两个手柄：左=改尺寸，右=等比缩放"}],
            ["Note", "UI_Label", {
                # 没有 max_chars：宽度**由面板给**（面板宽 - 内边距 24），所以拖大折行少、拖小折行多
                "content": "这段文字用来验证「以面板为准」：拖大面板，它折行会变少；拖小面板，折行会变多。"
                    + "文字宽度始终等于面板宽度减掉内边距，既不会把面板撑开，也不会被裁掉。",
            }],
        ],
    }],
    # 矩阵网格：版式写在面板 config 的 `matrix` 里（同一个数字出现几格 = 跨几格 / 跨几行）；
    # 想进网格的子元素写一个 `grid: 编号`，面板负责把它的 position/size 算好——
    # **拖右下角的"改尺寸"手柄，格子按矩阵比例跟着缩放**（排版不变）。
    # 不同位置可以用不同的元素：1–3、5–8 是纯标签，4 号是面板（里面还套着自己的子元素）。
    # 没写 `grid` 的子元素不参与网格；面板尺寸要定死（拖手柄改的就是它）。
    ["MatrixTest", "UI_Panel", {
        "position": [560, 40],
        "size": [500, 320],                            # 定死：矩阵按"内容区现在多大"算
        "margin": 8,
        "gap": 4,                                      # 格间距（不写 = 4）
        "matrix": [
            [1, 1, 1, 1, 1, 1],
            [2, 2, 2, 3, 3, 3],
            [4, 4, 5, 5, 6, 6],
            [4, 4, 7, 7, 8, 8],
        ],
        "events": [QName.UI_event_pointer1_drag, QName.UI_event_pointer2_menu],
        "children": [
            _gcell(1, "占满一整行"),
            _gcell(2, "半行·左"), _gcell(3, "半行·右"),
            # 4 号跨两行两列：用面板，里面还能套自己的子元素（跟着格子一起缩放）
            ["4", "UI_Panel", {
                "grid": 4, "margin": 0,
                "background": UIPreset_Keyboard.KEY_BG, "background_slice": UIPreset_Keyboard.KEY_BG_SLICE,
                "children": [["Text", "UI_Label", {
                    "content": "4：跨两行两列（面板里还能套元素）", "font_color": UIPreset_Keyboard.FONT_COLOR,
                }]],
            }],
            _gcell(5, "第三行·中"), _gcell(6, "第三行·右"),
            _gcell(7, "第四行·中"), _gcell(8, "第四行·右"),
        ],
    }],
    # 等大网格（背包）：每个格子一样大（`cell`），**列数随宽度变**——拖宽了东西就往上走一行；
    # 多出来不够一格的空位**摊进间距**（间距变宽，直到够塞下一列，那时列数 +1、间距回到最小）；
    # 排不下（行数 × 格子 + 间距 > 内容区高）⇒ 面板的滚动条出现。
    # 12 个格子：起始 260 宽 ⇒ 3 列 4 行；拖到 340 宽 ⇒ 4 列 3 行。
    ["BagTest", "UI_Panel", {
        "position": [560, 400],
        "size": [260, 320],
        "margin": 8,
        "gap": 6,                                      # 最小间距（余量不足一格时它会被撑大）
        "cell": [64, 64],                              # 等大格子（方形；长方形写 [宽, 高]）
        "events": [QName.UI_event_pointer1_drag, QName.UI_event_pointer2_menu],
        "children": _bag_cells(12),
    }],
    # 输入用：标题 + 输入框 + 一句提示；回车提交 → 发给绑定的那个 UI
    ["TestInput", "UI_Panel", {
        # 提交后写到哪儿：**一条路径**（不再有"先记名字、再按名字查"那层转手）。
        # 想发给别的 UI 就改这儿（或右键目标 → 菜单编辑 ▸ → 复制名称 → 填成一整条路径）。
        "content_cmd": "@UI/TestShow.config.content",   # 提交后写到哪儿：就一条路径（标准项，见 UIBase.refresh / UI_Editor）
        "position": [380, 190], "size": [260, 0],
        "events": [QName.UI_event_pointer2_menu],
        "children": [
            ["Title", "UI_Label", {"content": "TestInput（打字后回车）"}],
            ["Name", "UI_Input", {
                "size": [240, 0],
                # 输入框自己**没有任何特判**：点它进编辑、回车提交，都是这里配的事件→指令。
                "events": [
                    # 点它进编辑（元素不写死"鼠标左键"：换成别的事件照样能用）
                    QName.UI_event_pointer1_edit,
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
