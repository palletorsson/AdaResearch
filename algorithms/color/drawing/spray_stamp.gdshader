shader_type canvas_item;
render_mode unshaded;
uniform vec4 ink : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform float coverage = 0.1;
uniform float seed = 0.0;
uniform vec2 stamp_pixels = vec2(64.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.17) * 43758.5453); }
void fragment() {
    float r = length(UV * 2.0 - 1.0);
    float edge = 1.0 - smoothstep(0.88, 1.0, r);
    float dose = -log(max(1.0 - coverage, 0.0001));
    // Fine central fog, surrounded by separate droplets, not a blurred disc.
    float core = 1.0 - exp(-dose * 2.1 * exp(-7.0 * r * r));
    vec2 grain_pos = UV * stamp_pixels / 2.6;
    vec2 cell = floor(grain_pos);
    vec2 centre = vec2(hash(cell + 4.1), hash(cell + 29.3)) * 0.5 + 0.25;
    float droplet = 1.0 - smoothstep(0.12, 0.46, length(fract(grain_pos) - centre));
    float chance = 1.0 - exp(-dose * 13.0 * exp(-2.8 * r * r));
    float speck = step(hash(cell + 71.0), chance) * droplet * 0.68;
    float alpha = (1.0 - (1.0 - core) * (1.0 - speck)) * edge;
    COLOR = vec4(ink.rgb, clamp(alpha * ink.a, 0.0, 0.98));
}
