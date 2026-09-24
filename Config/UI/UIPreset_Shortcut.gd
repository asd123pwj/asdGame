class_name UIPreset_Shortcut
extends ConfigBase

""" ---------- 角色快捷监控（名称只读 / 状态与指令可改） ----------
 ▾ 系统快捷                          ← 头部（可折叠标题：点它整块收起 / 展开）
 ✕                              ← 右上角图标关闭（UIPreset_Basic.close_item）
 Body(UI_Shortcut)                   ← **内容是一个"快捷监控"元素**（Script/UI/UI/UI_Shortcut.gd）
   系统快捷：@Char/SYS  [刷新]（重读）   ← 元素铺的抬头（看的是哪个角色）
   共 5 条快捷（名称只读；状态 / 指令改完回车提交…）
   Submit                                   ← 名称（只读，亮）
       依赖状态（回车提交；改了会重新监听）
       [ Submit                    ]        ← 输入框：改"依赖哪个状态"，改完自动重听
       执行的指令（多条命令在预设里用 \v 分隔，这里显示成换行）
       [ PointerDetect.key("Submit") ]      ← 输入框：改"要跑什么指令"

**改的是预设**（一个快捷名全项目一份，见 SystemShortcutPreset._we）⇒ 所有装了这条快捷的角色都受影响；
改"依赖状态"会**重新监听**（旧的那条监听不换掉就等于写了个没人看的字段），改"指令"立刻生效（触发时现读）。

看哪个角色由 Body 的 `char` 决定（默认**系统角色 SYS**，改这一行就换人）；
开的时候也能临时指定（`content_cmd` 优先于 `char`，**开完点一下 `[刷新]` 生效**）：
  UIInteract.open(preset_name="Shortcut")
  UIInteract.open(preset_name="Shortcut", content_cmd="@Char/人类")   # 再点 [刷新]

**为什么内容交给元素而不是写在这儿**：一个角色装了哪些快捷、每条依赖哪个状态、要跑什么指令，
都是**运行期**数据（`Character.shortcuts`，装到角色身上才算数）。外壳只是"标题 + 关闭 + 一块内容"。
**这里不做实时**：快捷清单是原型里声明的，加删之后点 `[刷新]`（原因见 UI_Shortcut 的文件头）。
"""


## 独立 UI（不挂别的 UI 下面）：`open(preset_name="Shortcut")` 就开在配置声明的这个位置。
## `scroll` = [上限宽, 上限高]：宽写 0 = 跟着内容（写死宽会把长文案裁掉），高最多 520——再多只在框内滚动。
var values: Array[Array] = [
    ["Shortcut", "UI_Panel", {
        "position": [430, 40],                       # 摆在状态一览旁边（那个是 [40, 40]）
        # **不写 size**：宽度跟着内容走
        "scroll": [0, 520],                          # 宽不限（0 = 跟着内容）、高到 520 就进滚动
        "free": true,                                # 自由定位：位置不被父级布局改
        "events": [QName.UI_event_pointer1_drag],
        "children": [
            # 头部 = 可折叠标题（点它整块收起 / 展开；标题自己标了"收起时留着我"，收起来还点得回来）
            UIInteract_Fold.title_item("系统快捷", false, SysCfg.ui_view_chars),
            UIPreset_Basic.close_item(),   # 图标式关闭（右上角）：和 CloseButton 预设同一张图 / 同一套指令
            # 内容：快捷监控元素。`char` = 看哪个角色（指令路径/引用，要带 `@`）；
            # 不写就用 UI 通用的查看项 `content_cmd`（open 的时候能临时指定）。
            ["Body", "UI_Shortcut", {
                "char": "@Char/SYS",                 # 默认看系统角色；换人只改这一行
            }],
        ],
    }],
]
