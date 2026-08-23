// P3D 像素级遮挡掩码 shader
//
// 目标：被 tilemap 实际像素(alpha>0)覆盖的 P3D 像素不再显示。
//
// 原理：
//   生成一张与 tilemap 世界区域逐像素对齐的掩码纹理，每个像素代表一个世界像素，
//   红(1,0,0) 表示该世界像素被 tilemap 占用，黑/透明表示无。
//   fragment 里用精灵世界坐标(world_pos)采样掩码纹理，若被占用则 discard，
//   实现像素级的精确遮挡。
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D occlusion_mask : filter_nearest;
// 掩码纹理的像素尺寸 (宽, 高)，单位：世界像素
uniform vec2 mask_size = vec2(1.0, 1.0);
// 精灵左上角的世界坐标（sprite.position，已含伪3D 偏移）
uniform vec2 sprite_origin = vec2(0.0);
// 精灵纹理的像素尺寸（P3D 图集区域为 48x48）
uniform vec2 sprite_size = vec2(48.0, 48.0);
// 掩码采样偏移量（世界像素），用于手动校正遮挡对齐
uniform vec2 mask_offset = vec2(34.0, -14.0);

void fragment() {
    // 精灵像素的真实世界坐标，加上可调偏移后采样掩码纹理
    vec2 world_pos = sprite_origin + UV * sprite_size + mask_offset;
    vec2 mask_uv = world_pos / mask_size;
    if (mask_uv.x >= 0.0 && mask_uv.x < 1.0 && mask_uv.y >= 0.0 && mask_uv.y < 1.0) {
        float m = texture(occlusion_mask, mask_uv).r;
        if (m > 0.5) {
            discard;
        }
    }
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a < 0.01) {
        discard;
    }
    COLOR = tex;
}
