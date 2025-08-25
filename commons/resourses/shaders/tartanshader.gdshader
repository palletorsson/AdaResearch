shader_type spatial;
render_mode cull_disabled;

uniform vec2 uv_scale = vec2(40.0, 10.0);
uniform vec4 color_a : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_c : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_d : source_color = vec4(0.9450980392156862, 0.8509803921568627, 0.7215686274509804, 1.0);

// Additional parameters for variation
uniform float object_seed : hint_range(0.0, 1000.0) = 0.0;
uniform float color_randomness : hint_range(0.0, 1.0) = 0.5;
uniform float line_width_randomness : hint_range(0.0, 1.0) = 0.3;

// Simple hash function for randomization
float hash(float n) {
    return fract(sin(n * 43758.5453123) * 43758.5453123);
}

// Generate a random color based on seed
vec4 randomize_color(vec4 base_color, float seed_offset) {
    float r_rand = hash(object_seed + seed_offset);
    float g_rand = hash(object_seed + seed_offset + 13.7);
    float b_rand = hash(object_seed + seed_offset + 27.3);

    vec4 random_color = vec4(r_rand, g_rand, b_rand, base_color.a);
    return mix(base_color, random_color, color_randomness);
}

vec4 get_color(float x) {
    // Randomize line width by varying the frequency
    float base_frequency = 15.0;
    float frequency_variation = hash(object_seed + 100.0) * 10.0 * line_width_randomness;
    float stripe_frequency = base_frequency + frequency_variation;

    // Randomize stripe width threshold
    float base_width = 0.21;
    float width_variation = hash(object_seed + 200.0) * 0.15 * line_width_randomness;
    float stripe_width = base_width + width_variation;

    // Get randomized colors
    vec4 rand_color_a = randomize_color(color_a, 1.0);
    vec4 rand_color_b = randomize_color(color_b, 2.0);
    vec4 rand_color_c = randomize_color(color_c, 3.0);
    vec4 rand_color_d = randomize_color(color_d, 4.0);

    return (
        mix(
            mix(
                rand_color_d    // Randomized base color
            ,   mix(       // Black and white stripes with random frequency
                    rand_color_a
                ,   rand_color_b
                ,   clamp((sign(sin(x * PI * stripe_frequency)) + 1.0) / 2.0, 0.0, 1.0)
                )
            ,   float(abs(x - 0.5) < stripe_width)  // Randomized stripe width
            )
        ,   rand_color_c        // Randomized red accent
        ,   clamp((1.0 - sin(x * PI)) * 12.0 - 11.0, 0.0, 1.0)
        )
    );
}

void fragment() {
    vec2 uv_looped = mod(UV * uv_scale, vec2(1.0));
    ALBEDO = mix(get_color(uv_looped.x).rgb, get_color(uv_looped.y).rgb, 0.5);
}