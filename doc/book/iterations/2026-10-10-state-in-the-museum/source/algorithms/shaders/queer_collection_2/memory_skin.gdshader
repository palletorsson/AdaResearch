shader_type spatial;

// Agent-QueerFabricator: Memory Skin
// Aesthetic: Pale silicone that “remembers” touch (simulated via time/noise).
// Poetics: A body that answers back after you leave.
// Technique: Subsurface Scattering (SSS) + Time-varying "bruise" noise.

uniform vec3 skin_color : source_color = vec3(0.95, 0.9, 0.85); // Pale silicone
uniform vec3 bruise_color_1 : source_color = vec3(0.4, 0.1, 0.4); // Deep purple
uniform vec3 bruise_color_2 : source_color = vec3(0.1, 0.2, 0.5); // Blueish
uniform float roughness : hint_range(0.0, 1.0) = 0.4;

uniform sampler2D noise_tex : hint_default_white;
uniform float bruise_speed = 0.2;
uniform float bruise_scale = 2.0;

void fragment() {
    // Simulate "memory" by scrolling noise that reveals bruises
    vec2 uv_bruise = UV * bruise_scale;
    float n1 = texture(noise_tex, uv_bruise + vec2(TIME * bruise_speed * 0.5, 0.0)).r;
    float n2 = texture(noise_tex, uv_bruise - vec2(0.0, TIME * bruise_speed * 0.3)).r;
    
    // Intersect noise patterns to create irregular, organic shapes
    float bruise_mask = smoothstep(0.6, 0.8, n1 * n2);
    
    vec3 final_color = mix(skin_color, bruise_color_1, bruise_mask * 0.6);
    // Add secondary bruise color at edges
    float edge = smoothstep(0.5, 0.65, n1 * n2) - bruise_mask;
    final_color = mix(final_color, bruise_color_2, edge * 0.4);

    ALBEDO = final_color;
    ROUGHNESS = roughness;
    
    // Fake Subsurface Scattering (SSS)
    SSS_STRENGTH = 0.5;
    SSS_TRANSMITTANCE_COLOR = vec4(0.8, 0.4, 0.4, 1.0); // Reddish transmittance
    SSS_TRANSMITTANCE_DEPTH = 0.1;
    
    // Slight emission on bruises to make them "glow" or feel active
    EMISSION = bruise_color_1 * bruise_mask * 0.1; 
}
