class_name UI_Panel
extends UIBase
## 示例 UI 元素（设计见 Script/UI/UI.md）：一个面板，含文本框/按钮/滚动条。
## 覆写 _create_control 生成外观；交互（拖动/关闭/缩放/提交）由 UIBase 统一处理。

func _create_control() -> Control:
    var panel: PanelContainer = PanelContainer.new()
    panel.name = name

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 8)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_bottom", 6)
    panel.add_child(margin)

    var vbox: VBoxContainer = VBoxContainer.new()
    margin.add_child(vbox)

    var title: Label = Label.new()
    title.text = "UI_Panel: " + name
    vbox.add_child(title)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(280, 120)
    vbox.add_child(scroll)

    var content: Label = Label.new()
    var lines: PackedStringArray = PackedStringArray()
    for i in range(40):
        lines.append("第 %d 行：滚动查看内容。" % i)
    content.text = "\n".join(lines)
    content.custom_minimum_size = Vector2(260, 20 * 40)
    scroll.add_child(content)

    var close_btn: Button = Button.new()
    close_btn.text = "关闭"
    close_btn.pressed.connect(close)
    vbox.add_child(close_btn)

    return panel
