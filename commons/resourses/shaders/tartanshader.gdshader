shader_type spatial;
render_mode cull_disabled, vertex_lighting, specular_schlick_ggx;

uniform vec2 uv_scale = vec2(40.0, 10.0);
uniform vec4 color_a : source_color = vec4(1.0, 0.95, 0.1, 1.0);  // Bright yellow default
uniform vec4 color_b : source_color = vec4(1.0, 0.4, 0.0, 1.0);   // Orange default
uniform vec4 color_c : source_color = vec4(1.0, 0.1, 0.5, 1.0);   // Hot pink default
uniform vec4 color_d : source_color = vec4(0.2, 0.8, 1.0, 1.0);   // Sky blue default

// Brightness and vibrancy controls
uniform float brightness_boost : hint_range(0.5, 2.0) = 1.3;
uniform float saturation_boost : hint_range(0.5, 3.0) = 1.8;
uniform float contrast : hint_range(0.5, 2.0) = 1.2;

// Pattern variation parameters
uniform float object_seed : hint_range(0.0, 1000.0) = 0.0;
uniform float color_randomness : hint_range(0.0, 1.0) = 0.2;
uniform float line_width_randomness : hint_range(0.0, 1.0) = 0.3;

// Animation parameters for extra life
uniform float time_speed : hint_range(0.0, 1.0) = 0.1;

// Enhanced hash function for better randomization
float hash(float n) {
    return fract(sin(n * 12.9898 + 4.1414) * 43758.5453);
}

vec2 hash2(float n) {
    return fract(sin(vec2(n * 12.9898 + 4.1414, n * 7.269 + 3.1459)) * 43758.5453);
}
// HSV conversion functions
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);

// HSV conversion functions (must be defined before use)
}

// Color enhancement functions
vec3 boost_saturation(vec3 color, float boost) {
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    return mix(gray, color, boost);
}

vec3 boost_contrast(vec3 color, float contrast_level) {
    return (color - 0.5) * contrast_level + 0.5;
}

// Simpler color randomization that keeps colors bright
vec4 randomize_color_bright(vec4 base_color, float seed_offset) {
    vec2 rand = hash2(object_seed + seed_offset);
    
    // Keep the base color bright and just vary it slightly
    vec3 color = base_color.rgb;
    
    // Add small random variations while keeping brightness
    color.r = clamp(color.r + (rand.x - 0.5) * color_randomness * 0.3, 0.5, 1.0);
    color.g = clamp(color.g + (rand.y - 0.5) * color_randomness * 0.3, 0.5, 1.0);
    color.b = clamp(color.b + (rand.x * rand.y - 0.5) * color_randomness * 0.3, 0.5, 1.0);
    
    // Ensure at least one channel is very bright for vibrancy
    float max_channel = max(max(color.r, color.g), color.b);
    if (max_channel < 0.8) {
        color = normalize(color) * 0.9;
    }
    
    return vec4(color, base_color.a);
} 
 

 

// Enhanced tartan pattern generator
vec4 get_bright_tartan_color(float x) {
    // Add subtle time animation for living patterns
    float animated_time = TIME * time_speed;
    float time_wave = sin(animated_time + x * 2.0) * 0.05;
    x += time_wave;
    
    // Dynamic line width with more variation
    float base_frequency = 12.0 + hash(object_seed + 100.0) * 8.0;
    float frequency_variation = hash(object_seed + 200.0) * 15.0 * line_width_randomness;
    float stripe_frequency = base_frequency + frequency_variation;
    
    // Variable stripe widths for more organic feel
    float base_width = 0.15 + hash(object_seed + 300.0) * 0.2;
    float width_variation = hash(object_seed + 400.0) * 0.25 * line_width_randomness;
    float stripe_width = base_width + width_variation;
    
    // Get bright randomized colors
    vec4 bright_color_a = randomize_color_bright(color_a, 1.0);
    vec4 bright_color_b = randomize_color_bright(color_b, 2.0);
    vec4 bright_color_c = randomize_color_bright(color_c, 3.0);
    vec4 bright_color_d = randomize_color_bright(color_d, 4.0);
    
    // Enhanced pattern mixing with smoother transitions
    float stripe_pattern = (sign(sin(x * PI * stripe_frequency)) + 1.0) / 2.0;
    stripe_pattern = smoothstep(0.2, 0.8, stripe_pattern); // Smoother transitions
    
    // Create the base tartan pattern
    vec4 base_pattern = mix(
        bright_color_d, // Base color
        mix(bright_color_a, bright_color_b, stripe_pattern),
        float(abs(x - 0.5) < stripe_width)
    );
    
    // Add accent stripes with enhanced blending
    float accent_pattern = clamp((1.0 - sin(x * PI)) * 8.0 - 7.0, 0.0, 1.0);
    accent_pattern = smoothstep(0.3, 0.7, accent_pattern);
    
    vec4 final_color = mix(base_pattern, bright_color_c, accent_pattern * 0.8);
    
    return final_color;
}

void fragment() {
    vec2 uv_looped = mod(UV * uv_scale, vec2(1.0));
    
    // Get colors for both directions
    vec4 horizontal_color = get_bright_tartan_color(uv_looped.x);
    vec4 vertical_color = get_bright_tartan_color(uv_looped.y);
    
    // Enhanced blending for richer patterns
    vec3 mixed_color = mix(horizontal_color.rgb, vertical_color.rgb, 0.6);
    
    // Add subtle cross-hatching effect
    float cross_pattern = sin(uv_looped.x * PI * 20.0) * sin(uv_looped.y * PI * 20.0);
    cross_pattern = smoothstep(-0.5, 0.5, cross_pattern) * 0.1;
    mixed_color += cross_pattern;
    
    // Apply brightness and saturation boosts
    mixed_color = boost_saturation(mixed_color, saturation_boost);
    mixed_color = boost_contrast(mixed_color, contrast);
    mixed_color *= brightness_boost;
    
    // Ensure colors stay vibrant but not blown out
    mixed_color = clamp(mixed_color, 0.0, 1.0);
    
    ALBEDO = mixed_color;
    
    // Add slight emission for extra pop
    EMISSION = mixed_color * 0.05;
    
    // Material properties for better light interaction
    METALLIC = 0.1;
    ROUGHNESS = 0.4;
    SPECULAR = 0.8;
}