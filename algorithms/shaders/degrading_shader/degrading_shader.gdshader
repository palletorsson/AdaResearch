
shader_type spatial;

uniform sampler2D degradation_map : source_color;
uniform float degradation_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 base_color : source_color = vec3(0.75, 0.78, 0.82);
uniform float roughness_boost : hint_range(0.0, 1.0) = 0.6;
uniform float metallic_shift : hint_range(0.0, 1.0) = 0.15;
uniform float emission_strength : hint_range(0.0, 3.0) = 0.4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float imprint = texture(degradation_map, uv).r * degradation_amount;

    vec3 degraded = mix(base_color, vec3(0.18, 0.08, 0.02), imprint);
    float rough = clamp(ROUGHNESS + imprint * roughness_boost, 0.0, 1.0);
    float metal = clamp(METALLIC + imprint * metallic_shift, 0.0, 1.0);

    float grain = hash(uv * 512.0 + TIME) * 0.12 * imprint;
    ALBEDO = degraded + grain;
    ROUGHNESS = rough;
    METALLIC = metal;

    EMISSION = vec3(0.25, 0.18, 0.12) * imprint * emission_strength;
}
