class_name Utils
extends BaseClass
## 通用小工具：一部分是"按键路径（Array）读写嵌套字典"，一部分是**几个类要一起用的零碎**
## （位图哈希、调试图存盘——原来两个 Tilemap 预设各写一份一模一样的，收到这儿）。
## 路径例：[ "statuses", "Nourish", "time" ] → dict["statuses"]["Nourish"]["time"]。
## 被谁用：按路径存/取嵌套配置与状态的地方（如 StatusPreset / Attributes 的 keys 路径读写），
## 以及 TileSpritePreset / TileSetPreset（哈希与调试存盘）。


## 沿 keys 逐层取；中间缺任何一层就返回 default（不报错、不建节点）。
## 被谁用：按路径读取"可能不存在"的嵌套值。
static func find_dict(dict: Dictionary, keys: Array, default: Variant = {}):
    var current = dict
    for key in keys:
        if not current.has(key):
            return default
        current = current[key]
    return current

## 沿 keys 逐层写；中间缺的层自动建成空字典，最后一层赋 value。
## 被谁用：按路径写入嵌套值（写入会创建缺失的中间层）。
static func set_dict(dict: Dictionary, keys: Array, value: Variant) -> void:
    var current: Dictionary = dict
    for i in range(keys.size() - 1):  # 只到倒数第二个
        var key = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    current[keys[-1]] = value

## 通用"按路径写一个值"——**只有两个参数**（路径里已经带了宿主）。
## 路径语法与指令里**读值那套完全一致**（走的就是指令解析器，见 CommandParser.write）：
##   Utils.write("@123.config.content", 值)          ← 实例成员 / 字典键，想写几层写几层
##   Utils.write("Test.int1", 7)                     ← 类脚本的 static 变量
##   Utils.write("arr[2]", 值) / ("a.b[0].c", 值)    ← 中间夹列表下标
## 路径写成**带引号的字符串**即可：引号里的内容不再被当成取值式，路径原样传进来；
## 带不带前导 `$` 都行（等价，缺 `$` 由 CommandParser._normalize_path 补上）。
## 路径里的占位符照常由 指令系统（`@self`/`@host`/`@event`） 先换掉（`self` / `host` / `event`）——
## 所以"写到宿主上"直接写 `Utils.write("@host.config.content_cmd", 值)`，不必数 @self.parent 级数。
## 宿主/中间层取不到、最后一步不可写时返回 false 并**警告一声**（多半是路径写错）。
## 指令写法：Utils.write("@host.config.content_cmd", @self.control.text)
## 被谁用：配置里按路径写值（如"绑定"）。
static func write(path: Variant, value: Variant) -> bool:
    if CommandParser.write(str(path), value):
        return true
    push_warning("Utils.write: 写不进「%s」（路径取不到 / 最后一步不可写）" % str(path))
    return false


## 对调**两条路径**上的值（A ↔ B）——开关式按钮的"换一套配置"就是它。
## 也是**只有两个参数**（两条路径），走的是同一套路径解析（CommandParser.read / write）：
##   Utils.swap("@self.config.events", "@self.config.events_2")
##   Utils.swap("@self.config.content", "@self.config.content_2")
## 路径用双引号包住写成字符串（引号里的内容不再被当取值式）。
## 读不到 / 任一侧写不进就返回 false 并警告一声。
## **界面刷新不在这里**：UI 侧改完 config，在配置里紧接一条 `@self.refresh("content")`（改了什么刷什么）。
## 被谁用：开关式按钮的配置（原来那条 UIInteract.swap_config）。
static func swap(path_a: Variant, path_b: Variant) -> bool:
    var sa: String = str(path_a)
    var sb: String = str(path_b)
    var ra: Array = CommandParser.read(sa)
    var rb: Array = CommandParser.read(sb)
    if not ra[0] or not rb[0]:
        push_warning("Utils.swap: 读不到「%s」或「%s」（路径取不到？）" % [sa, sb])
        return false
    if not write(sa, rb[1]) or not write(sb, ra[1]):
        return false
    return true


## 把文本复制到**系统剪贴板**（平台没有剪贴板功能时警告，等于没复制成功）。
## 典型用法是内嵌取值：
##   Utils.copy(@host.config.reg_name)        ← 右键菜单的"复制名称"（host = 那个窗口）
## 被谁用：需要往外复制文本的配置（如"复制名称"）。
static func copy(text: Variant = "") -> void:
    var s: String = "" if text == null else str(text)
    if s == "":
        push_warning("Utils.copy: 收到空文本（取值失败？目标还没登记、config 里没有 reg_name？）")
        return
    if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
        DisplayServer.clipboard_set(s)
        print("[Utils.copy] 已复制：", s)
    else:
        push_warning("Utils.copy: 当前平台没有剪贴板，没复制成功：%s" % s)


## 位图（BitMap）→ MD5 串：**内容相同就是同一个键**（"同形状共享一份"的缓存键）。
## 两个 Tilemap 预设原来各写一份一模一样的（TileSpritePreset._hash_bitmap / TileSetPreset._hash_mask），收到这儿。
## 被谁用：TileSpritePreset.get_erase_id（擦除掩码）、TileSetPreset.get_or_register_masked_p3d（P3D 掩码）。
static func hash_bitmap(bit_map: BitMap) -> String:
    var region: Vector2i = Sys.sysCfg.REGION_SIZE
    var alpha := PackedByteArray()
    alpha.resize(region.x * region.y)
    var n := 0
    for y in region.y:
        for x in region.x:
            alpha[n] = 1 if bit_map.get_bit(x, y) else 0
            n += 1
    var ctx := HashingContext.new()
    ctx.start(HashingContext.HASH_MD5)
    ctx.update(alpha)
    return ctx.finish().hex_encode()


## 把一张图存进 `SysCfg.DEBUG_DIR`（目录不存在就建），失败报错——报错里带上 `tag` 说明是谁存的。
## 两个 Tilemap 预设原来各写一份一模一样的，收到这儿。
## 被谁用：TileSpritePreset._to_48_atlas / _create_source、TileSetPreset.save_all_tiles_debug。
static func save_debug_png(image: Image, file_name: String, tag: String) -> void:
    var debug_path: String = Sys.sysCfg.DEBUG_DIR + file_name
    DirAccess.make_dir_recursive_absolute(Sys.sysCfg.DEBUG_DIR)
    if image.save_png(debug_path) != OK:
        push_error("%s: 保存调试图像失败: %s" % [tag, debug_path])
