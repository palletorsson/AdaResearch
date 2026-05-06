shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 fill_color : source_color = vec4(0.2, 0.3, 0.8, 1.0);
uniform vec4 wireframe_color: source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float wireframe_width : hint_range(0.1, 10.0) = 2.0;
uniform float wireframe_brightness : hint_range(0.0, 5.0) = 2.0;
uniform bool show_only_wireframe = false;

varying vec3 barycentric;

void vertex() {
    int vid = VERTEX_ID % 3;
    barycentric = vec3(0.0);
    if (vid == 0) barycentric = vec3(1.0, 0.0, 0.0);
    else if (vid == 1) barycentric = vec3(0.0, 1.0, 0.0);
    else barycentric = vec3(0.0, 0.0, 1.0);
}

void fragment() {
    vec3 d = fwidth(barycentric);
    vec3 a3 = smoothstep(vec3(0.0), d * wireframe_width, barycentric);
    float edge_factor = min(min(a3.x, a3.y), a3.z);
    float wireframe_factor = 1.0 - edge_factor;

    if (show_only_wireframe) {
        ALBEDO = wireframe_color.rgb;
        EMISSION = wireframe_color.rgb * wireframe_brightness;
        ALPHA = wireframe_factor * wireframe_color.a;
        if (ALPHA < 0.01) discard;
    } else {
        ALBEDO = mix(fill_color.rgb, wireframe_color.rgb, wireframe_factor);
        EMISSION = wireframe_color.rgb * wireframe_factor * wireframe_brightness;
        ALPHA = mix(fill_color.a, wireframe_color.a, wireframe_factor);
    }
}