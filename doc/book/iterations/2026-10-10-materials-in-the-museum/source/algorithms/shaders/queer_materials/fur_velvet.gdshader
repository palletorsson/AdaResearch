shader_type spatial;

// Agent-Materialist: Queer Fur / Velvet
// Aesthetic: Soft, plush, touchable, luxurious.
// Description: Simulates the scattering of light on micro-fibers (velvet effect).

uniform vec3 albedo_color : source_color = vec3(0.5, 0.0, 0.2); // Deep red/purple
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform vec3 sheen_color : source_color = vec3(1.0, 0.5, 0.8);
uniform float sheen_sharpness : hint_range(0.0, 1.0) = 0.5;
uniform float sheen_intensity : hint_range(0.0, 5.0) = 2.0;

uniform float noise_scale = 100.0;
uniform float noise_depth = 0.1;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    float noise = random(UV * noise_scale);
    
    // Albedo
    ALBEDO = albedo_color;
    
    // High roughness for the base
    ROUGHNESS = roughness;
    METALLIC = metallic;
    
    // Velvet/Sheen effect (Rim lighting variation)
    // The "Asperity" of velvet comes from light grazing the fibers
    float NdotV = dot(normalize(NORMAL), normalize(VIEW));
    float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
    
    // Add noise to the rim to simulate individual hairs catching light
    float noisy_rim = smoothstep(0.0, 1.0, rim) * (0.8 + 0.4 * noise);
    
    // Sheen calculation
    vec3 sheen = sheen_color * pow(noisy_rim, 1.0 - sheen_sharpness) * sheen_intensity;
    
    // Apply sheen to albedo or emission depending on desired look.
    // For velvet, it often looks like emission or additive color.
    ALBEDO += sheen * 0.5;
    EMISSION = sheen * 0.2;
    
    // Normal perturbation for "softness"
    NORMAL_MAP = normalize(vec3(noise * noise_depth - (noise_depth/2.0), noise * noise_depth - (noise_depth/2.0), 1.0));
}
