shader_type spatial;

uniform sampler2D degradation_map;
uniform float degradation_amount = 0.0;
uniform vec3 intact_color = vec3(0.42, 0.45, 0.5);
uniform vec3 damage_color = vec3(0.12, 0.08, 0.02);
uniform float roughness_boost = 0.35;
uniform float metallic_boost = 0.05;
uniform float emission_strength = 0.25;
uniform float grain_strength = 0.08;

float rand_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float tex_sample = texture(degradation_map, uv).r;
    float imprint = clamp(pow(tex_sample, 1.35) * degradation_amount, 0.0, 1.0);
    float global_wear = degradation_amount * 0.18;
    float wear = clamp(global_wear + imprint, 0.0, 1.0);

    vec3 base_color = mix(intact_color, damage_color, wear);
    float rough = clamp(ROUGHNESS + wear * roughness_boost, 0.0, 1.0);
    float metal = clamp(METALLIC + wear * metallic_boost, 0.0, 1.0);

    float grain = (rand_hash(uv * 512.0 + TIME) - 0.5) * grain_strength * wear;
    ALBEDO = base_color + grain;
    ROUGHNESS = rough;
    METALLIC = metal;

    EMISSION = mix(vec3(0.0), damage_color * 0.6, wear) * emission_strength;
}
