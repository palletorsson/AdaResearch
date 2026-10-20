shader_type spatial;
render_mode cull_disabled;

// A bounded, normalized sum of value-noise octaves. No fluid state or collision.
uniform int octaves : hint_range(1, 4) = 3;
uniform float relief : hint_range(0.0, 0.25) = 0.15;
uniform float phase = 0.0;
uniform int mode : hint_range(0, 2) = 0; // colour, normal, vertex height
varying vec2 position_xz;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), u.x),
        mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), u.x), u.y);
}
float field(vec2 p) {
    vec2 drift = 0.9 * vec2(cos(phase), sin(phase));
    vec2 q = p + drift;
    float sum = 0.0, weight = 0.5, weights = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= octaves) { break; }
        sum += weight * (2.0 * noise2(q) - 1.0);
        weights += weight;
        weight *= 0.5;
        q *= 2.0;
    }
    return sum;
}
float height_at(vec2 p) { return relief * field(p); }
void vertex() {
    position_xz = VERTEX.xz;
    float h = height_at(position_xz);
    if (mode == 2) { VERTEX.y += h; }
    if (mode >= 1) {
        float e = 0.045;
        float dx = (height_at(position_xz + vec2(e, 0)) - height_at(position_xz - vec2(e, 0))) / (2.0 * e);
        float dz = (height_at(position_xz + vec2(0, e)) - height_at(position_xz - vec2(0, e))) / (2.0 * e);
        NORMAL = normalize(vec3(-dx, 1.0, -dz));
    }
}
void fragment() {
    float n = 0.5 + 0.5 * field(position_xz);
    vec3 pigment = mix(vec3(0.012, 0.07, 0.09), vec3(0.13, 0.52, 0.47), n);
    ALBEDO = pigment;
    ROUGHNESS = 0.15;
}
