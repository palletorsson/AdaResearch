shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 tint : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float strength = 0.35;
varying vec4 instance_tint;
void vertex() { instance_tint = COLOR; }
void fragment() {
    float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
    float edge = pow(1.0 - facing, 2.6);
    vec3 sheen = 0.74 + 0.26 * cos(12.0 * facing + vec3(0.0, 2.1, 4.2));
    ALBEDO = tint.rgb * instance_tint.rgb * sheen * 1.4;
    ALPHA = strength * (0.035 + 0.965 * edge) * instance_tint.a;
}
