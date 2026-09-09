# Tilemap · 地图系统

## 定位
把"图集素材"经"命名/切块/裁切/规则"预处理成 tile 预设，再按"放置规则"把 tile 放到分层地图上，供角色在地图上走动/交互。

## 文件
| 文件 | 作用 |
|---|---|
| `MapSystem.gd` | `MapSys`：地图总入口(层管理 + 放置 + 构建)。 |
| `MapLayer.gd` | 单个地图层(存内容、增量构建、放置队列)。 |
| `MapPlaceRulePreset.gd` | 放置规则预设(按规则放随机素材/tile)。 |
| `TileSetPreset.gd` | 把切好的图合成 Godot TileSet(变种/掩码)。 |
| `TileSpritePreset.gd` | 切图源：把一张图按命名规则切成多个 tile/变种(含掩码裁切)。 |
| `TileNameRulePreset.gd` | "tile 命名规则"预设(名字↔形状/在源图的位置)。 |
| `TileMatchRulePreset.gd` | "拼接匹配规则"预设(相邻判定)。 |
| `TileP3DEraseMask.gd` | P3D(伪3D)擦除掩码生成。 |

## MapSystem.gd（MapSys，extends BaseClass；命令宿主，方法即命令，如 `MapSys.place`）
- 静态：`layers`(各层 MapLayer)、`tile_set`、`SysCfg` 提供 REGION/GRID/TILE_MARGIN 等。
- `place(layer_id, x, y, source_name, tile_name, variant, force_space, force_compatible)`：在某格放某 tile(带变种随机/跳过判空/兼容等)。
- `build()`：增量遍历各层把待放内容真正落 TileMap。
- 其它：`map_layer_to_id/map_id_to_name` 等命令方法。
- 供谁调用：被 `Msg.send_cmd("MapSys.place ...")`(Command) 触发；命令内参数可用 `$`/`&` 取值表达式。

## MapLayer.gd（extends BaseClass）
- 一个 TileMapLayer：`_pending`/`to_place`(待放置集)、`get_source_at`、`build()`(刷待放内容并清空)、`_apply_tile_match`(放置后按匹配规则改邻居 tile)、`has_pending`。
- 供谁调用：MapSys 增量 build 各层。

## 各 Preset 分工（源图 → 规则 → TileSet）
- `TileSpritePreset`：以一张源图 + cell_sizes + tiles_name，按图像内容紧密裁出各 tile/变种并生成掩码；维护变种数与掩码(`get_group_variant_count` 等)。
- `TileNameRulePreset` / `TileMatchRulePreset`：分别描述"素材在图上叫什么/长什么样"、"相邻怎么拼接匹配"。
- `TileSetPreset`：把上面裁出的图按规则合成 Godot `TileSet`(变种展开/掩码贴图/拼图 debug)。
- `MapPlaceRulePreset`：提供"某格可随机放哪类素材"的放置规则。
- `TileP3DEraseMask`：伪3D 用的擦除掩码。

## 数据流转
源图 → `TileSpritePreset`(命名/切块/变种/掩码) → `TileSetPreset`(合成 TileSet) → `MapSys.place`(选素材/变种) → `MapLayer.build`(落 TileMap 并触发匹配) → 游戏内可见地图。
