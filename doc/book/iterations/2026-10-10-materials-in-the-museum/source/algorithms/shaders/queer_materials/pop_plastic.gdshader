shader_type spatial;

// Agent-Materialist: Pop Plastic / Latex
// Aesthetic: Artificial, high-gloss, candy-colored, "Super Pop".
// Description: A wet-look plastic shader with iridescent hints.

uniform vec3 albedo_color : source_color = vec3(1.0, 0.0, 0.8); // Hot Pink
uniform float roughness : hint_range(0.0, 1.0) = 0.05; // Very shiny
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 1.0;

uniform vec3 rim_color : source_color = vec3(0.0, 1.0, 1.0); // Cyan rim
uniform float rim_width : hint_range(0.0, 1.0) = 0.6;

uniform bool iridescent = true;
uniform float iridescence_strength = 0.5;

void fragment() {
    vec3 color = albedo_color;
    
    if (iridescent) {
        // Simple view-dependent color shift
        float NdotV = dot(normalize(NORMAL), normalize(VIEW));
        vec3 shift = vec3(sin(NdotV * 10.0), cos(NdotV * 10.0), sin(NdotV * 5.0 + 2.0));
        color = mix(color, shift * 0.5 + 0.5, iridescence_strength * (1.0 - NdotV));
    }
    
    ALBEDO = color;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = specular;
    
    // Sharp rim light for plastic look
    float NdotV = dot(normalize(NORMAL), normalize(VIEW));
    float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
    rim = pow(rim, 3.0); // Sharp falloff
    
    EMISSION = rim_color * rim * rim_width;
}
