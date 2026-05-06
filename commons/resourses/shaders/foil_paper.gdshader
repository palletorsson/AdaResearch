shader_type spatial;
render_mode cull_disabled;

uniform vec3 albedo : source_color = vec3(0.8, 0.8, 0.9);
uniform float metallic : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float crumple_scale = 5.0;
uniform float crumple_strength = 0.2;

// Simple noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    float n = noise(UV * crumple_scale);
    
    // Perturb normal based on noise to simulate crinkles
    vec3 normal_offset = vec3(
        noise(UV * crumple_scale + vec2(0.1, 0.0)) - 0.5,
        noise(UV * crumple_scale + vec2(0.0, 0.1)) - 0.5,
        0.0
    ) * crumple_strength;
    
    NORMAL = normalize(NORMAL + normal_offset);
    
    ALBEDO = albedo;
    METALLIC = metallic;
    ROUGHNESS = roughness + n * 0.2; // Crinkles are rougher
    SPECULAR = 0.8;
}
