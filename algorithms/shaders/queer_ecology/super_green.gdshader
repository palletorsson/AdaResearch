shader_type spatial;

// Agent-Ecologist: Super Green / Hyper-Nature
// Aesthetic: Chlorophyll overdose, radioactive growth, "The Green".
// Description: A pulsing, glowing organic shader.

uniform vec3 base_color : source_color = vec3(0.0, 0.8, 0.1); // Intense Green
uniform vec3 pulse_color : source_color = vec3(0.2, 1.0, 0.4); // Highlights
uniform float pulse_speed = 2.0;
uniform float pulse_amount = 0.1;

void vertex() {
    // Breathing motion
    float breathe = sin(TIME * pulse_speed) * pulse_amount;
    VERTEX += NORMAL * breathe;
}

void fragment() {
    // Generate procedural noise if texture is not provided (using simple sin waves)
    float n = sin(UV.x * 20.0 + TIME) * sin(UV.y * 20.0 + TIME);
    
    // Mix colors based on noise and time
    float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
    vec3 final_color = mix(base_color, pulse_color, pulse * 0.5 + n * 0.2);
    
    ALBEDO = final_color;
    
    // Subsurface scattering approximation (backlight)
    // In Godot, SSS is a specific parameter, but we can fake the glow
    SSS_STRENGTH = 0.8;
    SSS_TRANSMITTANCE_COLOR = vec4(1.0, 0.0, 0.0, 1.0); // Reddish blood/sap underneath
    
    // Bio-luminescent glow
    EMISSION = final_color * 0.2 * (pulse + 0.5);
    
    ROUGHNESS = 0.4; // Waxy leaf surface
}
