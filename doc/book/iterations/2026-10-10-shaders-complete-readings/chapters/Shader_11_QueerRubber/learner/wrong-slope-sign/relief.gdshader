shader_type spatial;
render_mode cull_disabled;

uniform sampler2D height_map : repeat_enable, filter_linear;
uniform sampler2D normal_map : hint_normal, repeat_enable, filter_linear;
uniform vec2 texel = vec2(0.00390625);
uniform float height_gain = 0.03;
uniform float strength = 0.6;
uniform float roughness = 0.35;
uniform int mode = 0;
uniform vec4 colour : source_color = vec4(0.42, 0.18, 0.10, 1.0);

void fragment() {
    vec3 encoded = vec3(0.5, 0.5, 1.0);
    if (mode == 1) {
        float left = texture(height_map, UV - vec2(texel.x, 0.0)).r;
        float right = texture(height_map, UV + vec2(texel.x, 0.0)).r;
        float above = texture(height_map, UV - vec2(0.0, texel.y)).r;
        float below = texture(height_map, UV + vec2(0.0, texel.y)).r;
        float du = (right - left) / (2.0 * texel.x);
        float dv = (below - above) / (2.0 * texel.y);
        vec3 direction = normalize(vec3(du * height_gain, dv * height_gain, 1.0));
        encoded = direction * 0.5 + 0.5;
    } else if (mode == 2) {
        encoded = texture(normal_map, UV).rgb;
    }
    NORMAL_MAP = encoded;
    NORMAL_MAP_DEPTH = strength;
    ALBEDO = colour.rgb;
    ROUGHNESS = roughness;
}
