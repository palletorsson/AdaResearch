shader_type spatial;

// Agent-QueerFabricator: Oil-Slick Latex
// Aesthetic: Black-hole gloss with rainbow edge interference.
// Poetics: A membrane that remembers the pressure of desire.
// Technique: High specular/roughness contrast + Thin-film interference (iridescence) on Fresnel.

uniform vec3 base_color : source_color = vec3(0.02, 0.02, 0.02); // Deep black/dark grey
uniform float roughness : hint_range(0.0, 1.0) = 0.15;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D noise_tex : hint_default_white;
uniform float slick_movement_speed = 0.1;
uniform float interference_strength = 1.5;

// Simple spectral approximation (rainbow)
vec3 spectrum(float t) {
    vec3 c = 0.5 + 0.5 * cos(6.28318 * (vec3(1.0) * t + vec3(0.0, 0.33, 0.67)));
    return c;
}

void fragment() {
    // Moving UVs for the "oil" feel
    vec2 uv_scroll = UV + vec2(TIME * slick_movement_speed, TIME * slick_movement_speed * 0.5);
    float noise = texture(noise_tex, uv_scroll).r;
    
    ALBEDO = base_color;
    
    // Vary roughness slightly based on noise for that "viscous" liquid look
    ROUGHNESS = roughness + (noise * 0.1); 
    METALLIC = metallic;
    SPECULAR = specular;
    
    // Thin-film interference / Iridescence logic
    float NdotV = dot(normalize(NORMAL), normalize(VIEW));
    float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
    
    // Perturb the rim calculation with noise to make it look like oil on water
    float perturbed_rim = rim + (noise * 0.2);
    
    // Calculate spectral color based on viewing angle
    vec3 rainbow = spectrum(perturbed_rim * 2.0 + TIME * 0.1);
    
    // Add iridescence to Emission or Albedo? 
    // For latex, it's usually a surface reflection effect.
    // Let's add it to Emission for that "pop" but keep it localized to glancing angles.
    vec3 oil_sheen = rainbow * pow(rim, 2.0) * interference_strength;
    
    EMISSION = oil_sheen;
    ALBEDO += oil_sheen * 0.2; // Blend a bit into base
}
