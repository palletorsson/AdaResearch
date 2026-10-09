shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
uniform sampler2D marks : source_color, filter_linear, repeat_enable;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
    vec3 p = normalize(local_position);
    vec2 uv = vec2(atan(p.z, p.x) / 6.28318530718 + 0.5, acos(clamp(p.y, -1.0, 1.0)) / 3.14159265359);
    vec4 ink = texture(marks, uv);
    float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
    ALBEDO = mix(vec3(0.18, 0.25, 0.32), ink.rgb, ink.a);
    EMISSION = ink.rgb * ink.a * 0.55;
    ALPHA = max(ink.a, edge * 0.065);
}

