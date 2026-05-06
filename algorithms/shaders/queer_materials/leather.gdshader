shader_type spatial;

// Agent-Materialist: Queer Leather
// Aesthetic: Fetish, tactile, high-contrast, shiny but imperfect.
// Description: A procedural leather shader that emphasizes the 'skin' aspect.

uniform vec3 albedo_color : source_color = vec3(0.05, 0.05, 0.05); // Default to deep black
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float grain_scale = 50.0;
uniform float grain_strength = 0.5;
uniform float fold_scale = 5.0;
uniform float fold_strength = 0.2;

uniform vec3 rim_color : source_color = vec3(0.2, 0.2, 0.2);
uniform float rim_width : hint_range(0.0, 1.0) = 0.5;
uniform float rim_sharpness : hint_range(0.0, 1.0) = 0.5;

// Simple noise function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    // Base grain noise (high frequency)
    float grain = noise(UV * grain_scale);
    
    // Larger fold noise (low frequency)
    float folds = noise(UV * fold_scale);
    
    // Combine for normal map perturbation
    float h = mix(grain, folds, 0.3);
    
    // Calculate normal from height map (simple partial derivatives)
    vec2 e = vec2(0.01, 0.0);
    float h_x = noise((UV + e) * grain_scale) - grain;
    float h_y = noise((UV + vec2(0.0, 0.01)) * grain_scale) - grain;
    
    vec3 normal_offset = vec3(-h_x * grain_strength, -h_y * grain_strength, 1.0);
    NORMAL_MAP = normalize(mix(vec3(0.5, 0.5, 1.0), normal_offset, 0.5));
    
    // Albedo with slight variation based on folds (wear and tear)
    ALBEDO = albedo_color * (0.8 + 0.2 * folds);
    
    ROUGHNESS = roughness + (1.0 - grain) * 0.2; // Valleys are rougher
    METALLIC = metallic;
    SPECULAR = specular;
    
    // Rim Light logic for that "fetish" shine
    float NdotV = dot(normalize(NORMAL), normalize(VIEW));
    float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
    rim = smoothstep(1.0 - rim_width, 1.0 - rim_width + (1.0 - rim_sharpness), rim);
    
    EMISSION = rim_color * rim;
}
