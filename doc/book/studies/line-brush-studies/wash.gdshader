shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform vec4 ink : source_color = vec4(1.0, 0.3, 0.6, 1.0);
uniform float opacity : hint_range(0.05, 1.0) = 0.34;
void fragment() {
    // Alpha coverage on a mesh, not a simulation of pigment or fluid.
    float edge = smoothstep(0.0, 0.16, UV.x) * smoothstep(0.0, 0.16, 1.0 - UV.x);
    float fibre = 0.91 + 0.09 * sin(UV.x * 95.0 + sin(UV.y * 37.0));
    ALBEDO = ink.rgb;
    ROUGHNESS = 0.67;
    ALPHA = opacity * edge * fibre;
}
