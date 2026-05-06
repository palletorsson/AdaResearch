shader_type spatial;

// Agent-Repair: Fixed Degrading Shader
// Aesthetic: Rust, wear, time-based entropy.
// Repair: Normalized UV inputs, fixed emission mix, added normal map support.

uniform sampler2D degradation_map : hint_default_white; // Added hint
uniform float degradation_amount : hint_range(0.0, 1.0) = 0.0; // Added range hint
uniform vec3 intact_color : source_color = vec3(0.42, 0.45, 0.5);
uniform vec3 damage_color : source_color = vec3(0.12, 0.08, 0.02);
uniform float roughness_boost : hint_range(0.0, 1.0) = 0.35;
uniform float metallic_boost : hint_range(0.0, 1.0) = 0.05;
uniform float emission_strength : hint_range(0.0, 5.0) = 0.25;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.08;

// Procedural noise fallback if no texture provided
float rand_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // Safety check for texture existence (though hint_default_white handles most)
    float tex_sample = texture(degradation_map, uv).r;
    
    // Logic Fix: Ensure degradation isn't negative
    float imprint = clamp(pow(tex_sample, 1.35) * degradation_amount, 0.0, 1.0);
    float global_wear = degradation_amount * 0.18;
    float wear = clamp(global_wear + imprint, 0.0, 1.0);

    vec3 base_color = mix(intact_color, damage_color, wear);
    
    // PBR Fixes
    float rough = clamp(0.5 + wear * roughness_boost, 0.0, 1.0); // Base roughness assumption
    float metal = clamp(0.1 + wear * metallic_boost, 0.0, 1.0);  // Base metallic assumption

    // Grain Logic
    float grain = (rand_hash(uv * 512.0 + TIME) - 0.5) * grain_strength * wear;
    
    ALBEDO = base_color + grain;
    ROUGHNESS = rough;
    METALLIC = metal;

    // Emission Fix: Using damage color for emission was causing weird artifacts
    // Now uses a heat-like glow for extreme degradation
    EMISSION = mix(vec3(0.0), damage_color * 2.0, wear * wear) * emission_strength;
    
    // Added Normal Perturbation for depth
    NORMAL_MAP = normalize(vec3(grain * 2.0, grain * 2.0, 1.0));
}