class_name UIPreset_MapCell
extends ConfigBase

""" ---------- 地图格瓦片查看（窗口） ----------
看**某一格**里放了哪些瓦片：一个世界层（`layer_id`）的几个子层（`Enums.LayerType`：
P3D / Middle / Plant / Furniture）在**同一格**各放了什么——

  · 头一行：**X / Y / Layer**（正在看哪一格）；
  · 第二张：**各子层那格瓦片按地图里的前后顺序叠在一起**（= 这块地方实际看起来的样子）；
  · 下面一排：**依次排列**每个子层一张（从左到右），各带一行短名（空的那层写"空"）；
  · 最下一行：**可改 X / Y / Layer**（三个输入框，回车提交）+ **实时监控**可选项。

**怎么开**：空地上右键 → 菜单"查看此格瓦片"（见 UIPreset_Menu 的 DesktopMenu），把**指针那一格**带进来。
窗口可拖动（按住空白处）、右上角图标关闭、右键还有管理菜单。

**实时监控**（那个可选项）：点一下切文本"关 / 开"，并**开 / 关一个保持型状态**
（`QName.map_monitor_on`，同 `QName.editing` 那套的手动状态）。实时的判据是**状态合成**：
`QName.map_monitor` = 「启用 ∧ 指针动过」（见 Archetype_System）——满足时由一条快捷指令
把**鼠标所属格**写进本窗口的 x / y（`UIInteract.open(..., x=…, y=…)` 复用 + 刷新），于是鼠标扫过哪格显示哪格。
**关掉监控**就只剩手动改 x / y / layer_id。开关的写法照抄菜单里"启用拖拽 / 添加关闭按钮"那套
（`content`/`content_2` + `events`/`events_2` + `Utils.swap`）。

**只读地图、不改地图代码**：全部走公开接口——
  · 子层节点：`MapSys.maps_parent_node` 里按 `CanvasLayer.layer`（= `MapLayer.sub_layer_id(layer_id, t)`）
    找那个 CanvasLayer，它的 `TileMapLayer` 子节点就是那一层；
  · 那一格放的瓦片：`TileMapLayer.get_cell_source_id / get_cell_atlas_coords / get_cell_alternative_tile`；
  · 贴图：共用的 `TileSpritePreset.tileset` 里按 source/coords 取区域 + 该瓦片的 `texture_origin`。
**只读，不动源节点**，地图照常跑。
"""


## 每张瓦片图（含头部那张）的边长（像素）。
## 取 64 = 图集区域 48 + 投影偏移（`texture_origin`，P3D 是 ±8）两边各留一点，保证不被切。
const ART := 64
## 依次排列里"格子与格子"的横向间距。
const GAP := 44
## 窗口内边距。
const PAD := 12
## 各行上边：头一行 / 头部图 / 一排图 / 一排说明 / 编辑行。
const HEAD_Y := 8
const PREVIEW_Y := 40
const TILES_Y := 112
const NAMES_Y := 178
const EDIT_Y := 204

## 头部 / 依次排列里出现的子层，**顺序 = 地图里的前后顺序**（子层号大的画在上面，
## 见 MapLayer.sub_layer_id：CanvasLayer.layer 越大越靠前）。
static var LAYERS: Array[int] = [
	Enums.LayerType.MIDDLE_P3D,
	Enums.LayerType.MIDDLE,
	Enums.LayerType.PLANT,
	Enums.LayerType.FURNITURE,
]

## 烘好的贴图缓存：key -> Texture2D（key 里带 layer_id + 格子坐标 ⇒ 换了格子不会拿到旧图）。
static var _cache: Dictionary = {}


# ---- 下面这些是给预设里 `content_cmd` 用的取值（格子/层从外壳 config 里传进来）----

## 外壳 config 里"看哪一格"：
##   · `cell`（**Vector2i**）：实时监控写进来的"鼠标所属格"——指令里写 `cell=PointerDetect.map_position`
##     （**别写 `…map_position.x`**：指令解析器不支持"静态变量后面再取属性"，那样会解析成 null）；
##   · 没有 `cell`（或已被手动编辑清掉）⇒ 用 `x` / `y` 两个键（三个输入框写的就是它们）。
## `cell` 有效时**顺手把 x / y 也同步过去**：于是输入框里显示的始终是"当前正看的那一格"。
static func cell_of(host: UIBase) -> Vector2i:
	var v: Variant = host.config.get("cell")
	if v is Vector2i:
		@warning_ignore("unsafe_cast")
		var cv: Vector2i = v
		host.config["x"] = cv.x
		host.config["y"] = cv.y
		return cv
	return Vector2i(_to_int(host.config.get("x")), _to_int(host.config.get("y")))


## 外壳 config 里"看哪个世界层"（`layer_id`），夹到合法范围。
static func layer_of(host: UIBase) -> int:
	return clampi(_to_int(host.config.get("layer_id")), 0, Enums.LayerType.COUNT - 1)


## 把 config 里那一项读成 int（空 / 输入框写回来的字符串 / 数字都认）。
## **不能直接 `int(v)`**：对上 null（指令里填错的键就是 null）会报 "Nonexistent 'int' constructor"。
static func _to_int(v: Variant) -> int:
	if v == null:
		return 0
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is String:
		@warning_ignore("unsafe_cast")
		var s: String = v
		if s.is_valid_int():
			return int(s)
	return 0


## 头一行："X: 5    Y: -15    Layer: 0"。
static func head_text(host: UIBase) -> String:
	var c: Vector2i = cell_of(host)
	return "X: %d    Y: %d    Layer: %d" % [c.x, c.y, layer_of(host)]


## **头部那张**：把各子层那格瓦片按顺序叠着烘进一张图（没瓦片的地方透明）——
## 几张都按同一条规则画（居中 + 各自的 `texture_origin`），所以叠起来就是"重叠后的样子"，
## 单独一张拿出来看也对得齐。
static func preview(host: UIBase) -> Texture2D:
	var c: Vector2i = cell_of(host)
	var l: int = layer_of(host)
	var key: String = "P|%d|%d|%d" % [l, c.x, c.y]
	if _cache.has(key):
		return _cache[key]
	var img: Image = _blank()
	for lt in LAYERS:
		_paint(img, l, c, lt)
	var tex: Texture2D = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## **依次排列里"某个子层"那一张**（那一子层在当前格没放瓦片就是一张透明图）。
static func art(host: UIBase, layer_type: int) -> Texture2D:
	var c: Vector2i = cell_of(host)
	var l: int = layer_of(host)
	var key: String = "A|%d|%d|%d|%d" % [l, c.x, c.y, layer_type]
	if _cache.has(key):
		return _cache[key]
	var img: Image = _blank()
	_paint(img, l, c, layer_type)
	var tex: Texture2D = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## 依次排列里那一行的短名（子层类型名太长，格子上摆不下）。
static func short_name(layer_type: int) -> String:
	match layer_type:
		Enums.LayerType.MIDDLE_P3D:
			return "P3D"
		Enums.LayerType.MIDDLE:
			return "Mid"
		Enums.LayerType.PLANT:
			return "Plant"
		Enums.LayerType.FURNITURE:
			return "Furn"
	return str(layer_type)


## 依次排列里那一行的说明：短名 + 有没有（空的那层写"空"）。
static func row_text(host: UIBase, layer_type: int) -> String:
	var name_: String = short_name(layer_type)
	if _tile_at(layer_of(host), cell_of(host), layer_type).is_empty():
		return "%s：空" % name_
	return "%s：有" % name_


# ---- 内部：找子层的 TileMapLayer、读那一格、把瓦片画进图 ----

## 一张全透明的 ART×ART 画布。
static func _blank() -> Image:
	return Image.create_empty(ART, ART, false, Image.FORMAT_RGBA8)


## 该子层在某格放的那块瓦片（只读公开 API）；没放返回空字典。
## 格子坐标要 **y 取反**：地图逻辑坐标 y 向上为正，TileMapLayer 里是 `Vector2i(x, -y)`（见 MapLayer._place_tile）。
static func _tile_at(layer_id: int, c: Vector2i, layer_type: int) -> Dictionary:
	var map: TileMapLayer = _sub_map(layer_id, layer_type)
	if map == null:
		return {}
	var gcell := Vector2i(c.x, -c.y)
	var sid: int = map.get_cell_source_id(gcell)
	if sid < 0:
		return {}
	return {
		"source_id": sid,
		"coords": map.get_cell_atlas_coords(gcell),
		"alt": map.get_cell_alternative_tile(gcell),
	}


## 某世界层某子层对应的 `TileMapLayer`：在 `MapSys.maps_parent_node` 里按 `CanvasLayer.layer`
## （= `MapLayer.sub_layer_id(layer_id, layer_type)`）认那个 CanvasLayer，再取它的 TileMapLayer 子节点。
## **全是公开节点与公开方法**（不改地图代码）。
static func _sub_map(layer_id: int, layer_type: int) -> TileMapLayer:
	var want: int = MapLayer.sub_layer_id(layer_id, layer_type)
	for child in MapSys.maps_parent_node.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == want:
			for sub in child.get_children():
				if sub is TileMapLayer:
					return sub
	return null


## 把某子层那格瓦片画进 `img`：按图集的纹理区域取那格像素，再按该瓦片的 `texture_origin` 偏移
## （P3D 才有偏移）。没放瓦片就什么都不画。
static func _paint(img: Image, layer_id: int, c: Vector2i, layer_type: int) -> void:
	var info: Dictionary = _tile_at(layer_id, c, layer_type)
	if info.is_empty():
		return
	var source: TileSetSource = TileSpritePreset.tileset.get_source(int(info["source_id"]))
	var atlas := source as TileSetAtlasSource
	if atlas == null or atlas.texture == null:
		return
	var atlas_img: Image = atlas.texture.get_image()
	if atlas_img == null:
		return
	var coords: Vector2i = info["coords"]
	var region: Rect2i = atlas.get_tile_texture_region(coords)
	if region.size.x <= 0 or region.size.y <= 0:
		return
	var origin := Vector2i.ZERO
	var td: TileData = atlas.get_tile_data(coords, int(info["alt"]))
	if td != null:
		origin = td.texture_origin
	# 居中 + 投影偏移：几张图都按这一条规则画 ⇒ 叠起来正好是"重叠的样子"。
	@warning_ignore("integer_division")
	var dst := Vector2i((ART - region.size.x) / 2, (ART - region.size.y) / 2) + origin
	img.blend_rect(atlas_img.get_region(region), Rect2i(Vector2i.ZERO, region.size), dst)


# ---- 预设的 children（构造器）----

## **自由定位子元素的"摆位两件套"**（`free` + `position`；要定尺寸再并上 `size`）——
## 本窗口的子元素都这么摆（不用面板的竖排：要的是"一行行按像素排"），所以收在一处，
## 免得每个元素都抄一遍这几个键。`size_` 传空数组 = 随内容。
static func _at(pos: Array, size_: Array = []) -> Dictionary:
	var c: Dictionary = {"free": true, "position": pos}
	if not size_.is_empty():
		c["size"] = size_
	return c


## 一项自由定位的子元素：`[名字, 类, 配置]`（`_at` 的摆位 + 自己的其它配置）。
## ⚠️ **文本类一定要给 `size`**：没有宽度上限的 free 文本会被压成 1px 宽、字竖着排成一列（实测踩过）。
static func _abs(name_: String, ui_class: String, pos: Array, size_: Array, cfg: Dictionary = {}) -> Array:
	var c: Dictionary = _at(pos, size_)
	c.merge(cfg, true)
	return [name_, ui_class, c]


## 窗口宽：两边内边距 + 4 张图 + 3 个间距（Head 也复用它算文字宽，别写两遍公式）。
static func _w() -> float:
	return PAD * 2 + LAYERS.size() * ART + (LAYERS.size() - 1) * GAP


## 窗口尺寸：高 = 编辑行 + 输入框高（一行 ~58）+ 内边距。
static func _size() -> Array:
	return [_w(), EDIT_Y + 58 + PAD]


## 依次排列里的"一个子层"：一张图 + 它下面一行说明（尺寸都写死，见 _abs）。
static func _tile_items(layer_type: int, x: float) -> Array:
	var name_w: float = ART + GAP - 8
	return [
		_abs("A%d" % layer_type, "UI_Image", [x, TILES_Y], [ART, ART],
			{"content_cmd": "UIPreset_MapCell.art(@self.parent, %d)" % layer_type}),
		_abs("N%d" % layer_type, "UI_Label", [x, NAMES_Y], [name_w, 24],
			{"content_cmd": "UIPreset_MapCell.row_text(@self.parent, %d)" % layer_type}),
	]


## 依次排列的全部子层（从左到右）。
static func _tiles() -> Array:
	var out: Array = []
	for i in LAYERS.size():
		out.append_array(_tile_items(LAYERS[i], PAD + i * (ART + GAP)))
	return out


## 一个"改格子的输入框"：短标签 + 输入框（回车提交，把文本写回外壳 config 的同名键，再刷一下）。
## 写法照抄 UI_Input 的常规用法（点进编辑 / 回车提交 / `Utils.write` 写回 / `UISys.refresh_all`）。
static func _edit(key: String, label: String, lx: float, ix: float) -> Array:
	return [
		_abs("E%s_L" % key, "UI_Label", [lx, EDIT_Y + 16], [18, 24], {"content": label}),
		_abs("E%s" % key, "UI_Input", [ix, EDIT_Y], [], {
			"content": "0",
			"content_cmd": "@self.parent.config.%s" % key,
			"max_chars": 4,
			"events": [
				[QName.pointer1_hold, 'UIInteract.begin_edit(@self)'],
				[QName.input_submit,
					'Utils.write("@self.parent.config.%s", @self.control.text)' % key
					# 顺手清掉 `cell`：手动改了 x / y / layer_id 之后，就该按手动值看（不然实时监控写的
					# 那个 `cell` 会一直盖着它）。不写值 = 置空（见 Utils.write / UI_Input 的说明）。
					+ '\vUtils.write("@self.parent.config.cell")'
					+ '\vUIInteract.end_edit(@self)'
					+ '\vUISys.refresh_all()'],
			],
		}),
	]


var values: Array[Array] = [
	["MapCell", "UI_Panel", {
		"x": 0, "y": 0, "layer_id": 0,                # 看哪一格 / 哪个世界层（输入框就是改这三项）
		"size": _size(),
		"free": true,
		# **不给 `position`**：实时监控每次刷新都会走一次 `open` 的摆位（CONFIG 策略），
		# 写死坐标的话会被拽回去、拖动白拖。不写 = 显示在哪就保持在哪（拖动一次就记住）。
		"open_at": Enums.OpenAt.CONFIG,
		# 按住空白处可拖（输入框自己配了按住 → 进编辑，不会冒泡上来）；右键 → 管理菜单（里面有"关闭"）。
		"events": [QName.UI_event_pointer1_drag, QName.UI_event_pointer2_menu],
		"children": [
			# 头一行：正在看哪一格（X / Y / Layer）
			_abs("Head", "UI_Label", [PAD, HEAD_Y], [_w() - PAD * 2, 24],
				{"content_cmd": "UIPreset_MapCell.head_text(@self.parent)"}),
			# 头部：各子层叠在一起的样子
			_abs("Preview", "UI_Image", [PAD, PREVIEW_Y], [ART, ART],
				{"content_cmd": "UIPreset_MapCell.preview(@self.parent)"}),
			UIPreset_Basic.close_item(),               # 右上角图标关闭
			# **实时监控**可选项：形状走通用模板（见 UIPreset_Basic.toggle_item）——
			# 差异只有两套文字 + 第一条命令（开 / 关那个保持型状态）。
			UIPreset_Basic.toggle_item("MonitorToggle", "实时监控：关", "实时监控：开",
				'Msg.send_status_detected_manual(Sys.sys_status, QName.map_monitor_on)',
				'Msg.send_status_undetected_manual(Sys.sys_status, QName.map_monitor_on)',
				_at([PAD + 278, EDIT_Y + 8], [110, 24])),
		] + _tiles() + _edit("x", "X", PAD, PAD + 18) + _edit("y", "Y", PAD + 94, PAD + 112) \
			+ _edit("layer_id", "L", PAD + 188, PAD + 206),
	}],
]
