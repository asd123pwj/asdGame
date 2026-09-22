class_name UI_Editor
extends UI_Panel
## **自适应编辑器**：把"要看 / 要改的那个东西"铺成可编辑的界面，**不挑数据长什么样**——按类型自主选择
## 编辑方式（这就是"自适应"）：
##   **字典** ⇒ 一行一键（键名 + 值编辑器）；字典数组 ⇒ 一项一段（可折叠，展开才建里面的编辑器）；
##   **数字 / 真假 / 文本 / 数组** ⇒ 直接就一个模板控件（见 kinds）。
## **编辑对象由 UI 通用的"查看项"指定**（跟别的 UI 显示什么用的是同一套，见 UIBase.refresh / _target_path）：
##   `content_cmd`（指令版本，优先）= 对象在哪；`content` 是字符串时也当路径；都没写 = host 的 config。
## 于是"编辑角色的属性、编辑某个全局字典"都不用改本元素——**把对象指过去就行**；任何一次 open 也能带
## 一个对象过来（`UIInteract.open(..., content_cmd="…")`）。
##
## config（除通用项外）：
##   kinds    { 类型: **模板** }：按类型给默认模板（`dict` / `dicts` / `list` / `text` / `number` / `bool`，见 DEFAULT_KINDS）。
##   special  { 键名: **模板** }：个别键单独指定（优先于 kinds），如 `{"children": ["UI_Editor", {"collapsed": true}]}`。
##   模板两种写法：`"预设名"`（换模板最省事，见 Config/UI/UIPreset_Editor*.gd）或 `[元素类名, 配置片段]`；
##   元素类是本类 = "**递归一个编辑器**"（套在可折叠的一段里，`collapsed` 决定默认收不收）。
##
## **交给模板的三个配置键**：`content`（当前值）、`source`（写回路径）、`target`（所属 UI 的登记名，纯数据时为空）。
## 模板没写 `events` 时，本元素补上默认那套（点进编辑 + 回车提交写回 + 重应用 + 刷新）。
##
## 读用 `CommandParser.read`（不经消息系统），写一律走**路径**（读到的可能是副本）。
## 子元素要登记（登记要拿父级名字）⇒ 内容在**自己登记好之后**才铺（见 on_registered）。

## 默认模板表：类型 → 模板（预设名 / [元素类, 配置]）。
const DEFAULT_KINDS: Dictionary = {
	"dict": ["UI_Editor", {}],
	"dicts": ["UI_Editor", {"collapsed": true}],
	"text": "UIEditorText",
	"list": "UIEditorText",
	"number": "UIEditorNumber",
	"bool": "UIEditorNumber",
}

## 铺过没有（只铺一次；重登记不重铺）。
var _built: bool = false


## 登记完成 ⇒ 铺内容（见 UIBase.on_registered：铺出来的子元素要登记，得等自己有名字）。
## **推迟一帧再铺**：`open` 那次"临时传进来的配置"（`config=…` / `content_cmd=…`）是在建完之后才 merge 到
## 配置上的，登记这一刻还读不到（实测：铺的时候 `parent` 上还没有 `content_cmd`）。等一帧，配置就齐了，
## 于是"编辑对象"无论来自预设、open 临时指定、还是运行中改，都能吃到。
func on_registered() -> void:
	if _built:
		return
	_built = true
	Callable(self, "_fill").call_deferred()


## 重新铺一遍（内容里那行"[重建]"调它）：清掉旧的、按现在的结构再铺。
func rebuild() -> void:
	clear_children()                 # 摘子树收在 UIBase（别在这儿再写一份，见 UIBase.clear_children）
	_built = true
	_fill()


## 铺：先"待编辑对象"是哪本（文字 + [重建] 一行），再按它的类型 / 键一个个来。
func _fill() -> void:
	if control == null:
		return                      # 这一帧里已经被移除了（重建 / 关掉了），别铺了
	add_child_element("Where", "UI_Label", {
		"content": "编辑：%s" % _target_path(),
		"font_color": Color(0.55, 0.60, 0.70),
	})
	add_child_element("Rebuild", "UI_Label", {
		"content": "[重建：重读]",
		"events": [[QName.mouseLeft, "@self.parent.rebuild()"]],     # 整行一条方法调用（父级 = 本元素）
	})
	var data: Variant = CommandParser.read(_target_path())[1]
	if not (data is Dictionary):
		# 不是字典（数字 / 真假 / 文本 / 数组 / 别的对象）：**不自作主张**，交给"这块数据该用哪个模板"，
		# 直接摆一个控件——于是"编辑器"对任何数据都成立（字典只是最常吃的那种）。
		var spec: Array = _spec_by_type(_type_of(data))
		add_child_element("Value", str(_spec_parts(spec)[0]), _value_cfg(_spec_parts(spec)[1], data))
		return
	var keys: Array = (data as Dictionary).keys()
	keys.sort()
	for k in keys:
		if str(k).begins_with("_"):
			continue                     # `_` 开头 = 元素内部影子键（如 _content_static），不给人编辑
		for frag in _frags(str(k), (data as Dictionary)[k]):
			add_child_element(str(frag[0]), str(frag[1]), frag[2])


## 一个键 → 它那几块片段（一个键可能铺出多段，如字典数组）。
func _frags(key: String, value: Variant) -> Array:
	var spec: Array = _spec(key, value)
	if str(spec[0]) == "UI_Editor":
		return _editor_sections(key, value, spec[1])
	return _row(key, value, spec)          # 一行 = 键名 + 模板控件 两条片段（别再包一层）


## 用"递归编辑器"这个模板铺：字典 ⇒ 一段；数组 ⇒ 每项一段（`collapsed` 决定默认收不收）。
func _editor_sections(key: String, value: Variant, conf: Variant) -> Array:
	var folded: bool = conf is Dictionary and bool((conf as Dictionary).get("collapsed", false))
	if not (value is Array):
		return [_section("%s：字典" % key, "%s.%s" % [_target_path(), key], folded)]
	var out: Array = []
	var index: int = 0
	for item in value:
		var sec: Array = _section_of(key, index, item)
		out.append(_section(str(sec[0]), str(sec[1]), folded))
		index += 1
	return out


## 一行"键名 + 模板控件"。
func _row(key: String, value: Variant, spec: Array) -> Array:
	var parts: Array = _spec_parts(spec)
	return [
		["Key", "UI_Label", {"content": key, "font_color": Color(0.62, 0.68, 0.78)}],
		["Value", str(parts[0]), _value_cfg(parts[1], value, key)],
	]


## 给模板控件配配置：把"当前值 / 写回路径 / 所属 UI"塞进去（模板没写 events 就补默认那套）。
func _value_cfg(conf: Dictionary, value: Variant, key: String = "") -> Dictionary:
	var cfg: Dictionary = conf.duplicate(true)
	cfg["content"] = _text_of(value)
	cfg["source"] = _target_path() if key == "" else "%s.%s" % [_target_path(), key]
	cfg["target"] = _owner_name()
	if not cfg.has("events"):
		cfg["events"] = [QName.UI_event_mouseLeft_edit, [QName.input_submit, _write_cmd(key)]]
	return cfg


## 一段可折叠分组：标题是折叠交互那套；里面的编辑器写进 `items`，**首次展开时才建**。
func _section(title: String, source: String, folded: bool) -> Array:
	return ["Sec", "UI_Panel", {
		"size": [0, 0],
		"collapsed": folded,
		"items": [["Ed", "UI_Editor", {"content_cmd": source}]],
		"children": [UIInteract_Fold.title_item(title, folded)],
	}]


## 字典数组里的一项 → [标题, 它那个编辑器的 target]。
## 三元组 `[名字, 元素类, 配置]`（配置里声明的子元素）⇒ **按登记名寻址**（`父名/名字.config`）；
## 其余（纯字典等）⇒ 按"父字典的这个键"当一本字典看。
func _section_of(key: String, index: int, item: Variant) -> Array:
	if item is Array and (item as Array).size() >= 3 and (item as Array)[2] is Dictionary:
		var child: String = str((item as Array)[0])
		return ["子UI：%s（%s）" % [child, str((item as Array)[1])], "%s/%s.config" % [_owner_ref(), child]]
	return ["%s[%d]" % [key, index + 1], "%s.%s" % [_target_path(), key]]


## 这个键用哪个模板：special（按键名）→ kinds（按类型）→ 默认表（都查不到按文本）。
func _spec(key: String, value: Variant) -> Array:
	var special: Variant = config.get("special")
	if special is Dictionary and (special as Dictionary).has(key):
		return _spec_normalize((special as Dictionary)[key])
	return _spec_by_type(_type_of(value))


## 按类型取模板（kinds 优先，其次默认表）。
func _spec_by_type(type_: String) -> Array:
	var kinds: Variant = config.get("kinds")
	if kinds is Dictionary and (kinds as Dictionary).has(type_):
		return _spec_normalize((kinds as Dictionary)[type_])
	return _spec_normalize(DEFAULT_KINDS.get(type_, DEFAULT_KINDS["text"]))


## 模板写法归一：`"预设名"` ⇒ 展开成 `[预设的元素类, 预设的配置]`；`[元素类, 配置]` 原样。
func _spec_normalize(spec: Variant) -> Array:
	if spec is String:
		var preset: UIPreset = UIPreset.get_(spec)
		if preset == null:
			push_warning("UI_Editor: 没有「%s」这个模板预设（见 Config/UI/）" % spec)
			return ["UI_Input", {}]
		return [preset.ui_name, preset.config.duplicate(true)]
	if spec is Array and (spec as Array).size() >= 2:
		return [spec[0], spec[1]]
	return ["UI_Input", {}]


## 模板 → [元素类名, 配置片段]。
func _spec_parts(spec: Array) -> Array:
	var conf: Dictionary = {}
	if spec[1] is Dictionary:
		conf = spec[1]
	return [str(spec[0]), conf]


## 数据的类型（决定默认用哪个模板，见 DEFAULT_KINDS）。
func _type_of(value: Variant) -> String:
	if value is Dictionary:
		return "dict"
	if value is Array:
		for item in value:
			if item is Array and (item as Array).size() >= 3 and (item as Array)[2] is Dictionary:
				return "dicts"                          # 配置里声明的子元素那种数组
		return "list"
	if value is String:
		return "text"
	if value is bool:
		return "bool"
	if value is int or value is float:
		return "number"
	return "text"


## 提交时跑的那条指令（模板没自己写 events 时的默认那套）：**一行**，调本元素的 write（逻辑收在这儿，
## 模板不必各写一份；它自己写了 events 就按它自己的来）。
func _write_cmd(key: String) -> String:
	return "@self.parent.write(@self.config.source, @self.control.text)"


## **提交一条**（模板控件的默认提交走它）：文本 → 值 → 按路径写回 → 刷新那个 UI。
## 文本 → 值：数字 / 真假 / `[...]` / `{...}` 按写法解析；**其余原样当字符串**。
## ⚠️ 这条兜底很关键：普通一段文字（如"欢迎"）用解析器会**算不出来 ⇒ null**，直接写下去就是
## "一提交把原来的清空"（实测踩过）。**解析不出来 = 它就是一段文本**，别丢。
## 被谁用：各行的提交指令 `@self.parent.write(@self.config.source, @self.control.text)`。
func write(path: String, text: String) -> void:
	if path == "":
		push_warning("UI_Editor: 这一行没有可写的路径（source），已忽略")
		return
	var value: Variant = CommandParser.parse_value(text)
	if value == null and not text.strip_edges().is_empty():
		value = text
	Utils.write(path, value)
	_refresh_owner(path)


## 写完后刷新"路径指着的那个 UI"：`…/Info.config.xxx` ⇒ 刷 `…/Info`（改了 host 自己身上的东西就刷 host）。
## 被谁用：write。
func _refresh_owner(path: String) -> void:
	var at: int = path.find(".config")
	var owner: String = ""
	if at > 0:
		owner = path.substr(0, at)
	else:
		var host_ref: String = "@" + RegSys.name_of(_find_host())
		if host_ref != "@" and path.begins_with(host_ref + "."):
			owner = host_ref
	if not owner.begins_with("@"):
		return
	var ui: UIBase = UISys.get_ui(owner.substr(1)) as UIBase
	if ui == null:
		return
	ui.reapply()
	ui.refresh()


## **编辑 / 监视的对象**在哪（跟着 UI 通用的"查看项"走，所以任何 open 都能指定）。按顺序找：
##   1. 本元素自己的 `content_cmd`（指令版本，优先）/ `content`（是字符串就当路径）——嵌套编辑器就是它；
##   2. **沿外壳往上**找第一处 `content_cmd` —— `open(..., content_cmd="…")` 写在外壳那一层的 config 上，
##      一次就对整块生效（元素不必知道外壳套了几层）；
##   3. 都没有 ⇒ host 的 config ⇒ "右键某个 UI → 编辑器"就是编辑它，开箱即用。
## 只认祖先的 `content_cmd`、**不认祖先的 `content` 字面值**：那多半是"这个 UI 显示的文字"，不是"对象在哪"。
func _target_path() -> String:
	var own: String = _object_of(config)
	if own != "":
		return own
	var up: UIBase = parent
	while up != null:
		var cmd: String = str(up.config.get("content_cmd", ""))
		if cmd != "":
			# **祖先上写的也要展开相对写法**：菜单项那层写的常常就是 `"host.config"`（见 UIPreset_Menu），
			# 直接拿原样字符串去 read 会读不到（`host` 不是真的成员名）⇒ 元素只能当"单个值"摆个输入框。
			return _expand_relative(cmd)
		up = up.parent
	var host_name: String = RegSys.name_of(_find_host())
	return "@" + host_name + ".config" if host_name != "" else "@self.config"


## 一本 config 里有没有写"对象在哪"：`content_cmd` 优先，其次字符串形式的 `content`。
func _object_of(cfg: Dictionary) -> String:
	var cmd: String = str(cfg.get("content_cmd", ""))
	if cmd == "":
		var c: Variant = cfg.get("content")
		if c is String:
			cmd = str(c)
	return _expand_relative(cmd) if cmd != "" else ""


## **相对写法**：`host.` 开头 ⇒ 展开成"本条链管理对象的引用"（如 `"host.config"` = 编辑这个 UI 自己）。
## **这里不该写 `@`**（写 `@host.…` 会在**派发事件那一刻**被指令系统解析成当时那个 host 的注册名；
## 而这条路径是**存起来、以后由元素自己读**的，那时没有事件上下文 ⇒ 存相对写法最稳）。为少踩坑，
## 写成 `@host.…` 也认（下面先把可能的前导 `@` 去掉）。
## 被谁用：_object_of、_target_path（祖先链那一支）。
func _expand_relative(cmd: String) -> String:
	var s: String = cmd.substr(1) if cmd.begins_with("@") else cmd
	if not s.begins_with("host."):
		return cmd
	var host_name: String = RegSys.name_of(_find_host())
	return "@" + host_name + "." + s.substr(5) if host_name != "" else ""


## 待编辑对象所属的那个 UI 的引用（路径以 `.config` 结尾时就是它）；纯数据给空串。
func _owner_ref() -> String:
	var s: String = _target_path()
	return s.substr(0, s.length() - 7) if s.ends_with(".config") else ""


## 来源所属 UI 的**登记名**（交给模板当 `target`；纯数据给空串，见文件头）。
func _owner_name() -> String:
	var ref: String = _owner_ref()
	return ref.substr(1) if ref.begins_with("@") else ""


## 值的显示文本：字符串原样（别在框里显示成带引号）、null 空、其余 str()。
func _text_of(value: Variant) -> String:
	if value == null:
		return ""
	if value is String:
		return value
	return str(value)
