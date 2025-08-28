shader_type spatial;

uniform float wave_amplitude = 0.2; // How large the wave is
uniform float wave_frequency = 2.0; // Speed of the wave
uniform float wave_length = 5.0; // Length of the wave
uniform float time_scale = 1.0; // Controls time speed
uniform float color_speed = 1.0; // Speed at which colors change

void vertex() {
    // Simulate wave effect on the arrow along the Z-axis
    float wave = sin(TIME * wave_frequency + VERTEX.z * wave_length) * wave_amplitude;

    // Move vertices up and down in the Y-axis (wave motion)
    VERTEX.y += wave;

    // Apply a gentle offset to make the wave more "swim-like"
    VERTEX.x += wave * 0.2;
}

void fragment() {
    // Generate a rainbow color based on time and vertex position
    float rainbow_factor = TIME * color_speed + VERTEX.z * wave_length;

    vec3 rainbow_color;
    rainbow_color.r = 0.5 + 0.5 * sin(rainbow_factor + 0.0);
    rainbow_color.g = 0.5 + 0.5 * sin(rainbow_factor + 2.0);
    rainbow_color.b = 0.5 + 0.5 * sin(rainbow_factor + 4.0);

    ALBEDO = rainbow_color;
}
