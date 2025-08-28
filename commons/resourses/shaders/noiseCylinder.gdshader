shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;
uniform float noise_speed : hint_range(0.0, 5.0) = 0.1;
uniform vec3 base_color : source_color = vec3(0.5, 0.8, 1.0);

float hash(vec2 p) {
    p = fract(p * 0.3183099 + vec2(0.1, 0.7));
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

void fragment() {
    vec2 uv = UV;
    uv.y += TIME * noise_speed; // Animate noise
    float noise_val = noise(uv * noise_scale);

    // Base color modulated by noise
    ALBEDO = base_color + vec3(noise_val * 0.2);
    EMISSION = vec3(noise_val * 0.5);
}
