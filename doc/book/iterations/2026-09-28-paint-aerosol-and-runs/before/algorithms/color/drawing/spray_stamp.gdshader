shader_type canvas_item;
render_mode unshaded;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float coverage = 0.1;
uniform float seed = 0.0;
uniform vec2 stamp_pixels = vec2(128.0);
float grain(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.19) * 43758.5453);
}
void fragment() {
    float radius = length(UV * 2.0 - 1.0);
    float envelope = exp(-3.5 * radius * radius) * (1.0 - smoothstep(0.75, 1.0, radius));
    float droplets = mix(0.3, 1.7, grain(floor(UV * stamp_pixels)));
    COLOR = vec4(ink.rgb, ink.a * clamp(coverage * envelope * droplets, 0.0, 0.95));
}
