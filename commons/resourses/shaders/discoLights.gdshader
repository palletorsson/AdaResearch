shader_type spatial;

uniform float time_speed : hint_range(0.1, 5.0) = 5.0; // Speed of color changes
uniform vec3 base_color  = vec3(0.5, 0.5, 0.5); // Base light color
uniform float intensity_factor : hint_range(0.1, 2.0) = 1.0; // Factor for intensity pulsing

// Helper to generate smooth color transitions
vec3 disco_color(float time) {
    return vec3(
        0.5 + 0.5 * sin(time * 3.0), // Red channel
        0.5 + 0.5 * sin(time * 2.0 + 1.0), // Green channel
        0.5 + 0.5 * sin(time * 4.0 + 2.0)  // Blue channel
    );
}

void light() {
    // Get the current time and modulate it
    float t = TIME * time_speed;

    // Compute dynamic light color
    vec3 light_color = disco_color(t) * base_color;

    // Pulse the light intensity dynamically
    float pulsing_intensity = 0.5 + 0.5 * sin(t * 2.0) * intensity_factor;

    // Apply the disco effect
    DIFFUSE_LIGHT = vec3(light_color) * pulsing_intensity;
}
