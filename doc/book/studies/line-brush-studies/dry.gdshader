shader_type spatial;
render_mode cull_disabled;
uniform vec4 ink : source_color = vec4(1.0, 0.3, 0.6, 1.0);
void fragment() {
    // Discard fragments along bristle lanes. The triangles still exist.
    float lane = floor(UV.x * 37.0);
    float seed = fract(sin(lane * 12.9898) * 43758.5453);
    float bristle = sin(UV.x * 232.48 + sin(UV.y * 11.0) * 0.9);
    float broken = sin(UV.y * (19.0 + seed * 21.0) + seed * 17.0);
    float edge = smoothstep(0.0, 0.055, UV.x) * smoothstep(0.0, 0.055, 1.0 - UV.x);
    if (bristle < -0.1 || broken < -0.52 || edge < seed * 0.75) { discard; }
    ALBEDO = ink.rgb * (0.83 + 0.17 * seed);
    ROUGHNESS = 0.94;
}
