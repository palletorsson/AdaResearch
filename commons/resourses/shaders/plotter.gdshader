shader_type spatial;

uniform float mytime; // Controls animation (increment this over time)
uniform float speed = 1.0; // Speed of paper movement
uniform float amplitude = 0.5; // Base amplitude of the seismic wave
uniform float frequency = 2.0; // Base frequency of the seismic line
uniform float noise_strength = 0.3; // Adds randomness to the wave
uniform float jitter_strength = 0.2; // Additional noise/jitter
uniform float line_offset = 0.0; // Horizontal offset for centering
uniform vec3 paper_color = vec3(1.0, 1.0, 1.0); // Color of the paper
uniform vec3 line_color = vec3(0.0, 0.0, 0.0); // Color of the seismic line

// Custom pseudo-random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Noise function for smooth randomness
float noise(vec2 co) {
    vec2 p = floor(co);
    vec2 f = fract(co);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(rand(p), rand(p + vec2(1.0, 0.0)), f.x),
        mix(rand(p + vec2(0.0, 1.0)), rand(p + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void fragment() {
    vec2 uv = UV; // Use the surface's UV coordinates

    // Normalize UV to make the paper center-aligned
    uv = uv * 2.0 - 1.0; // Scale UV from [0, 1] to [-1, 1]

    // Scroll the paper vertically
    uv.y -= mytime * speed;

    // Generate a noisy sine wave
    float random_amplitude = amplitude + noise(vec2(uv.y, mytime)) * noise_strength;
    float random_frequency = frequency + noise(vec2(uv.y * 2.0, mytime)) * noise_strength;
    float wave = sin(uv.y * random_frequency) * random_amplitude;

    // Add jitter for additional randomness
    wave += noise(vec2(uv.y * 10.0, mytime)) * jitter_strength;

    // Center the wave in the middle of the paper horizontally
    wave += line_offset;

    // Create the line by checking proximity to the wave
    float line_thickness = 0.02; // Thickness of the line
    float line = smoothstep(line_thickness, 0.0, abs(uv.x - wave));

    // Combine the paper and line colors
    vec3 final_color = mix(paper_color, line_color, line);

    // Assign the color to the ALBEDO
    ALBEDO = final_color;
}
