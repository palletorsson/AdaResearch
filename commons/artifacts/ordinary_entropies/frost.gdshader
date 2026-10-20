// Neighbourhood sampling spreads detail; alpha-only frosting merely dims it.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float obscurity : hint_range(0.0, 1.0) = 0.55;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
    float radius = 0.052 * pow(obscurity, 1.3);
    float aspect = VIEWPORT_SIZE.y / max(1.0, VIEWPORT_SIZE.x);
    float start = hash(FRAGCOORD.xy) * 6.2831853;
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 16; i++) {
        float f = float(i);
        float angle = start + f * 2.399963;
        float r = radius * sqrt((f + 0.5) / 16.0);
        sum += texture(screen_tex, SCREEN_UV + vec2(cos(angle)*aspect, sin(angle))*r).rgb;
    }
    float milk = obscurity >= 0.99 ? 1.0 : 0.03 + obscurity * 0.22;
    vec3 glass = mix(sum / 16.0, vec3(0.72, 0.79, 0.77), milk);
    float edge = pow(1.0 - min(min(UV.x, 1.0-UV.x), min(UV.y, 1.0-UV.y))*2.0, 35.0);
    ALBEDO = glass + edge * 0.06 + (hash(FRAGCOORD.xy*0.71)-0.5)*0.018*obscurity;
    ALPHA = 1.0;
}
