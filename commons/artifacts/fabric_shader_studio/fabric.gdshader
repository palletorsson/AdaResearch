shader_type spatial;
render_mode cull_disabled;
uniform sampler2D motif : source_color, filter_nearest, repeat_enable;
uniform float repeats = 4.0;
uniform float phase = 0.0;
uniform bool cut_out = false;
uniform bool metal_finish = false;
uniform bool uv_view = false;
uniform float amplitude = 0.0;
void vertex() {
    VERTEX += NORMAL * amplitude * sin(UV.y * 18.849556 + UV.x * 6.283185);
}
void fragment() {
    vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
    if (cut_out && fract(address.x) > 0.8) discard;
    ALBEDO = uv_view ? vec3(UV, 0.25) : texture(motif, address).rgb;
    ROUGHNESS = metal_finish ? 0.22 : 0.92;
    METALLIC = metal_finish ? 0.85 : 0.0;
}
