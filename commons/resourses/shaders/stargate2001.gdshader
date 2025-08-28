shader_type spatial;

uniform float time : hint_range(0, 100.0);  // Time input to animate the effect
uniform float speed = 1.0;  // Control the speed of the animation
uniform float intensity = 0.5;  // Intensity of the color distortion
uniform float wave_freq = 5.0;  // Frequency of the wave pattern
uniform float wave_amp = 0.1;  // Amplitude of the wave distortion
uniform vec3 color_1 = vec3(1.0, 0.0, 0.0);  // Main color 1
uniform vec3 color_2 = vec3(0.0, 0.0, 1.0);  // Main color 2
uniform float fade_intensity = 1.0;  // For possible fading effects
uniform bool mirror_x = true;  // Mirror the animation horizontally
uniform bool mirror_y = false;  // Mirror the animation vertically

void fragment() {
    vec2 uv = UV.xy;  // Get UV coordinates

    // Mirroring UV coordinates horizontally
    if (mirror_x) {
        uv.x = abs(fract(uv.x * 2.0) - 1.0);  // Flip horizontally
    }

    // Mirroring UV coordinates vertically
    if (mirror_y) {
        uv.y = abs(fract(uv.y * 2.0) - 1.0);  // Flip vertically
    }

    // Apply some wave-like distortion based on time
    float wave = sin(uv.y * wave_freq + TIME * speed) * wave_amp;

    // Distort the UV coordinates to create a warp effect
    uv.x += wave;

    // Additional dynamic warping and streaks
    uv.y += sin(uv.x * 10.0 + time * speed * 0.5) * 0.02;
    uv.x += cos(uv.y * 15.0 + time * speed * 0.5) * 0.02;

    // Create a smooth gradient transition between two colors
    vec3 color_mix = mix(color_1, color_2, uv.y + sin(time * 0.5));

    // Intensity-based color manipulation
    vec3 final_color = color_mix * (1.0 + intensity * sin(time + uv.x * 10.0));

    // Apply fading effect based on fade_intensity
    final_color *= fade_intensity;

    // Output the final pixel color
    ALBEDO = final_color.rgb;
}
