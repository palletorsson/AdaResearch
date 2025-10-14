shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, blend_premul_alpha;

uniform vec4 fill_color : source_color = vec4(0.9, 0.4, 0.4, 0.6);
uniform float fill_amount : hint_range(0.0, 1.0) = 0.0;
uniform float filled_alpha : hint_range(0.0, 1.0) = 0.5;
uniform float unfilled_alpha : hint_range(0.0, 1.0) = 0.12;

void fragment() {
    float y = UV.y;
    bool filled = (y < fill_amount);
    ALBEDO = fill_color.rgb;
    ALPHA = mix(unfilled_alpha, filled_alpha, float(filled));
}
