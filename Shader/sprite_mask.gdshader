// P3D 遮挡擦除 shader
//
// 说明：Sprite2D(AtlasTexture) 的 UV 是 atlas 图的坐标(0~1 覆盖整张图集)，不是精灵内 0~1。
//   通过 region_offset / region_scale 把 UV 转换到精灵内局部 UV(0~1)，再采样 48x48 擦除掩码。
//   掩码红 = 该局部像素被邻居 tile 遮挡，按 mode 置红或 discard。
shader_type canvas_item;
render_mode blend_mix, unshaded;

// region 在 atlas 图中的 UV 起点和尺寸(0~1)，用于把 atlas UV 转成精灵内局部 UV
uniform vec2 region_offset = vec2(0.0);
uniform vec2 region_scale = vec2(1.0);
// 48x48 擦除掩码纹理（用精灵内局部 UV 采样）
uniform sampler2D erase_mask : filter_nearest;
// 模式：0 = 置红(可视化)，1 = 删除(discard 挖空)
uniform int mode = 1;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a < 0.01) {
        discard;
    }
    // atlas UV -> 精灵内局部 UV
    vec2 local_uv = (UV - region_offset) / region_scale;
    bool in_mask = local_uv.x >= 0.0 && local_uv.x <= 1.0 &&
                   local_uv.y >= 0.0 && local_uv.y <= 1.0;
    float m = 0.0;
    if (in_mask) {
        m = texture(erase_mask, local_uv).r;
    }
    if (m > 0.5) {
        if (mode == 0) {
            COLOR = vec4(1.0, 0.0, 0.0, 1.0);  // 置红可视化
        } else {
            discard;  // 删除该位置(挖空)
        }
    } else {
        COLOR = tex;
    }
}
