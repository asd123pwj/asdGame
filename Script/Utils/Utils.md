# Utils · 通用基础

## 定位
项目最底层通用件：枚举、配置基类、预设注册、通用工具。**设计文档.md** 里 PresetRegister/ConfigBase/参数设计的规范即基于此处。

## 文件
| 文件 | 作用 |
|---|---|
| `Enums.gd` | 全局枚举(Code/ValueType/ModificationMethod/KeyStatus/LayerType 等)。 |
| `ConfigBase.gd` | 配置类基类(values 批量存配置，支持用户 json 覆盖)。 |
| `PresetRegister.gd` | 配置注册/装载基类(扫描 Config/ 下继承它的配置类)。 |
| `ChangeResult.gd` | 属性改动结果(状态码/原值/新值/偏移)。 |
| `ListenType.gd` | 一个"监听规则"(名字+比较符+阈值)，check() 判断。 |
| `Utils.gd` | 通用小工具(字典嵌套读写)。 |

## Enums.gd
- `enum Code`(NULL/OK/NOT_MODIFIED/FORBIDDEN/NOT_FOUND)、`ValueType`(BASE/CUR/MIN/FINAL/MULTIPLIER)、`ModificationMethod`(ADD/SUBTRACT/...)、`KeyStatus`(DOWN/FIRST_DOWN/UP/FIRST_UP)、`LayerType`(地图层)。
- `static StrValueType`、`StrLayerType` 字符串数组(配/显用)；`layer_can_match/layer_incompatible`(地图层匹配/不兼容表)。
- 供谁调用：全项目统一枚举。

## ConfigBase.gd（extends BaseClass）
- 子类声明 `values: Array[Dictionary]` + 字段。
- `_init`：读/存用户 json(`Sys.USER_CONFIG_DIR`)，无则保存默认；`RESET` 时重置。
- 提供 `_assign_property`(给对象按字段名赋值)、`script.get_global_name()` 等。
- 供谁调用：一切配置类(Archetype_Basic/UIPreset_Basic 等)继承它。

## PresetRegister.gd（extends BaseClass）
- 作为"注册/装载"根：`_init` 时扫描 `Config/` 下 `base==自身名` 的配置类子类，实例化并 `register`；也可 `_scan_dir` 按文件名前缀加载。
- 供谁调用：`Sys.presets = PresetRegister.new()`(在 Sys.init)；各域 Preset 的装载。

## ChangeResult.gd / ListenType.gd / Utils.gd
- ChangeResult：`code/ori/new/offset`，属性改动回调的返回体。
- ListenType：`name/match_type/thres` + `check(a,b)`(比较符：== != >= <= > <)。
- Utils：`find_dict/set_dict/get_or_set_dict`(按键数组嵌套读写字典)、`identity`。
