shader_type spatial;

// Uniforms to control the thickness of the line and noise influence
uniform float line_thickness = 0.05;
uniform float noise_amplitude = 0.01;  // Amplitude of the noise effect
uniform float noise_frequency = 2.0;  // Frequency of the noise

// Simple noise function using a sine wave
float noise(float x) {
    return sin(x * 12.9898 + 78.233) * 43758.5453 - floor(sin(x * 12.9898 + 78.233) * 43758.5453);
}

void fragment() {
    // Normalized coordinates, with (0,0) at the center of the screen
    vec2 uv = UV * 2.0 - 1.0;

    // Parameters for the sine wave
    float frequency = 4.0; // Frequency of the sine wave
    float amplitude = 0.6; // Amplitude of the sine wave
    float speed = 1.0; // Speed of the sine wave

    // Add noise to the sine wave calculation
    float noise_effect = noise(uv.y * noise_frequency + TIME) * noise_amplitude;

    // Calculate the sine wave based on the y coordinate and time
    float x = sin(uv.y * frequency + TIME * speed) * amplitude + noise_effect;

    // Calculate the distance to the sine wave
    float d = abs(uv.x - x);

    // Set the color to green, adjusting the smoothstep parameters to control line thickness
    vec3 col = vec3(0.0, 1.0, 0.0) * (1.0 - smoothstep(0.0, line_thickness, d));

    // Output the color
    ALBEDO = col;
}
