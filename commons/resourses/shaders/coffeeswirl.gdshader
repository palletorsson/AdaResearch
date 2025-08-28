shader_type spatial;
render_mode unshaded;

// Coffee dynamics parameters
uniform float time_scale = 0.5;
uniform float mix_ratio = 0.5; // 0 = black (coffee), 1 = white (milk)
uniform float entropy = 0.5; // Disorder (0-1)
uniform float complexity = 0.5; // Swirl complexity (0-1)
uniform vec4 coffee_color : source_color = vec4(0.36, 0.25, 0.20, 1.0);
uniform vec4 milk_color : source_color = vec4(1.0);

// Pattern generation
uniform sampler2D noise_texture;
uniform float swirl_speed = 0.5;

void fragment() {
    // Normalize UV coordinates (-1 to 1)
    vec2 uv = UV * 2.0 - 1.0;
    float time = TIME * time_scale;

    // Convert to polar coordinates (for better swirling)
    float r = length(uv);
    float theta = atan(uv.y, uv.x);

    // Entropy-driven turbulence
    vec2 entropy_offset = vec2(
        sin(time * 0.7 + uv.y * 4.0) * 0.3 * entropy,
        cos(time * 0.5 + uv.x * 4.0) * 0.3 * entropy
    );

    // Swirling effect based on time and entropy
    float swirl_factor = swirl_speed * (1.0 + complexity);
    theta += swirl_factor * sin(time * 0.8 + r * 4.0) * (1.0 - entropy);

    // Convert back to cartesian coordinates
    uv.x = r * cos(theta);
    uv.y = r * sin(theta);

    // Add multi-layered swirl distortion
    float swirl = 0.0;
    for(int i = 1; i < 4; i++) { // More octaves for turbulence
        float fi = float(i);
        uv.x += 0.3 / fi * sin(fi * uv.y + time * swirl_speed + entropy);
        uv.y += 0.3 / fi * cos(fi * uv.x + time * swirl_speed + entropy);
        swirl += (1.0 / fi) * sin(uv.x * fi * 6.0 + time) * complexity;
    }

    // Coffee-milk mixing based on swirl
    vec4 base_mix = mix(coffee_color, milk_color, mix_ratio);

    // Noise-based entropy pattern
    float noise = texture(noise_texture, uv * (1.0 + entropy * 1.5) + entropy_offset).r;
    float pattern = smoothstep(0.2, 0.8, noise + swirl * (1.0 - entropy));

    // Final color transition with richer browns
    float brown_transition = smoothstep(0.4, 1.0, entropy);
    vec3 final_color = mix(
        base_mix.rgb * pattern,
        vec3(0.5, 0.3, 0.2) * (1.0 - pattern), // Deeper coffee brown
        brown_transition
    );

    // Apply final color and transparency
    ALBEDO = final_color;
    ALPHA = 1.0;
}
