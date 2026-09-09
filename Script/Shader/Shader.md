# Shader · 着色器

## 定位
管理 `.gdshader` 着色器文件的按名加载与访问。着色器实际定义在 `Script/Shader/Shaders/` 下(资源)。

## 文件
| 文件 | 作用 |
|---|---|
| `ShaderManager.gd` | `ShaderManager`：扫描 `Sys.sysCfg.SHADERS_DIR` 目录加载 shader，按名访问。 |
| `Shaders/` | `.gdshader` 着色器资源文件(如 p3d 掩码相关)。 |

## ShaderManager.gd（extends BaseClass）
- `static _shaders: Dictionary`(文件名→Shader)，`_init` 触发 `_load_shaders()`。
- `static _load_shaders()`：遍历 `Sys.sysCfg.SHADERS_DIR`，加载所有 `.gdshader`(去扩展名作键)。
- `static get_shader(name)` / `has_shader(name)`：按名取/查。
- 供谁调用：需要给材质/贴图设 shader 的代码(如图像处理/掩码生成，参考 Tilemap 的 P3D 相关)。
